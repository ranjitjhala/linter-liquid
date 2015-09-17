# linter-liquid

This package will lint your opened Haskell in Atom, using [liquidhaskell](https://hackage.haskell.org/package/liquidhaskell).

![linter-liquid in action](https://raw.githubusercontent.com/ranjitjhala/linter-liquid/master/screenshot.png)

## Installation

* Install [liquidhaskell](https://hackage.haskell.org/package/liquidhaskell)
* `$ apm install linter` (if you don't have [AtomLinter/Linter](https://github.com/AtomLinter/Linter) installed)
* `$ apm install language-haskell` (for [Haskell syntax highlighting](https://github.com/jroesch/language-haskell) installed)
* `$ apm install linter-liquid`
* Specify the path to `liquid` in the settings.  You can find the path by using `which liquid` in the terminal

## Known Issues

Since the plugin needs to run `liquid` you must either have it in your
path, or provide the full path as described above. The latter is recommended
especially if you run `atom` from outside a shell (e.g. by the result of
"spotlight search" on MacOS).
