{BufferedProcess, CompositeDisposable} = require 'atom'
{XRegExp}                              = require 'xregexp'
{Process}                              = require 'process'
{Annotations, debugLiquidUtils}        = require 'liquid-utils'

pat1 = '(?<filename>.+?):(?<line>\\d+):(?<col>\\d+):(?<message>(\\s+.*\\n)+)'
pat2 = '(?<filename>.+?):(?<line>\\d+):(?<col>\\d+)-(?<colE>\\d+):(?<message>(\\s+.*\\n)+)'
pat3 = '(?<filename>.+?):\((?<line>\\d+),(?<col>\\d+)\)-\((?<lineE>\\d+),(?<colE>\\d+)\):(?<message>(\\s+.*\\n)+)'

strNum = (s) ->
  Number(s) - 1

matchError = (fp, match) ->
  lineS = strNum match.line
  lineE = if match.lineE then strNum match.lineE else lineS
  colS  = strNum match.col
  colE  = if match.colE then strNum match.colE else (colS + 1)
  type: 'Error'
  text: match.message,
  filePath: match.filename.trim(),
  range: [ [lineS, colS], [lineE, colE + 1] ]

last = (a) ->
  return a[a.length - 1]

matchResult = (str) ->
  strs = str.split('*******************\n')
  console.log(strs)
  if (strs.length > 0)
    return last(strs).substring(5).trim()
  return ""

infoErrors = (fp, str) ->
  info = matchResult(str)
  console.log ("LIQUID: begin:" + info + ':end')
  if (!info)
    return []
  errors = []
  regex = XRegExp.union [pat1, pat2, pat3]
  # regex = XRegExp pat2
  for msg in info.split(/\r?\n\r?\n/)
    XRegExp.forEach msg, regex, (match, i) ->
      e = matchError(fp, match)
      console.log('LIQUID: error:', e)
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
    @annotProvider = new Annotations('liquid', [], '.liquid')
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-liquid.liquidExecutablePath',
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
          filePath = textEditor.getPath()
          return @annotProvider.getErrors(filePath)  
