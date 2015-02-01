# ChromePipe Extension

## An experiment in a JavaScript UNIXy terminal

* Free in the [Chrome Store](https://chrome.google.com/webstore/detail/chromepipe/ikkdlidmhdbibjhhakdjcjeganhgbnmf)
* [Exciting video!](https://vimeo.com/118090094)

# Technologies

* JavaScript
* CoffeeScript
* jQuery
* SelectorGadget

# Local Development

## Compiling

Start by installing development dependencies with

    bundle

and then run

    bundle exec guard

## Chrome Extension

`guard` will automatically compile the chrome extension in `compiled/chrome-extension` and `compiled/chrome-extension.zip`.  You can load this into Chrome by going to Extensions, then clicking "Developer mode", and then "Load unpacked extension..." and selecting the `compiled/chrome-extension` directory.

## Testing

JavaScript and CoffeeScript is tested with [http://pivotal.github.com/jasmine/](jasmine).  With guard running,
open _spec/SpecRunner.html_ in your browser to run the tests.  (On a Mac, just do `open spec/SpecRunner.html`.)
