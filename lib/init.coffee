{BufferedProcess, CompositeDisposable} = require 'atom'
{XRegExp}   = require 'xregexp'
{Process}   = require 'process'

pat1 = '(?<filename>.+?):(?<line>\\d+):(?<col>\\d+):(?<message>(\\s+.*\\n)+)'
pat2 = '(?<filename>.+?):(?<line>\\d+):(?<col>\\d+)-(?<colE>\\d+):(?<message>(\\s+.*\\n)+)'
pat3 = '(?<filename>.+?):\((?<line>\\d+),(?<col>\\d+)\)-\((?<lineE>\\d+),(?<colE>\\d+)\):(?<message>(\\s+.*\\n)+)'

strNum = (s) ->
  Number(s) - 1

matchError = (fp, match) ->
  lineS = strNum match.line
  lineE = if match.lineE then strNum match.lineE else lineS
  col   = strNum match.col
  colE  = if match.colE then strNum match.colE else (colS + 1)
  type: 'Error'
  text: match.message,
  filePath: match.filename,
  range: [ [lineS, colS], [lineE, colE] ]

infoErrors = (fp, info) ->
  # console.log ("begin:" + info + ':end')
  if (!info)
    return []
  errors = []
  regex = XRegExp.union [pat1, pat2, pat3]
  for msg in info.split(/\r?\n\r?\n/)
    XRegExp.forEach msg, regex, (match, i) ->
      e = matchError(fp, match)
      # console.log('error:', e)
      errors.push(e)
  return errors

getUserHome = () ->
  p = process.platform
  v = if p == 'win32' then 'USERPROFILE' else 'HOME'
  # console.log(p, v)
  process.env[v]

module.exports =
  config:
    liquidExecutablePath:
      title: 'The liquid executable path.'
      type: 'string'
      default: 'liquid'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-liquid.hdevtoolsExecutablePath',
      (executablePath) =>
        @executablePath = executablePath

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      grammarScopes: ['source.haskell']
      scope: 'file' # or 'project'
      lintOnFly: true # must be false for scope: 'project'
      lint: (textEditor) =>
        return new Promise (resolve, reject) =>
          filePath = textEditor.getPath()
          message  = []
          # console.log ("exec: " + @executablePath)
          # console.log ("path: " + textEditor.getPath())
          # console.log ("zog : " + getUserHome())
          process = new BufferedProcess
            command: @executablePath
            args: [ filePath]
            stderr: (data) ->
              message.push data
            stdout: (data) ->
              message.push data
            exit: (code) ->
              # return resolve [] unless code is 0
              info = message.join('\n').replace(/[\r]/g, '')
              return resolve [] unless info?
              resolve infoErrors(filePath, info)

          process.onWillThrowError ({error,handle}) ->
            atom.notifications.addError "Failed to run #{@executablePath}",
              detail: "#{error.message}"
              dismissable: true
            handle()
            resolve []
