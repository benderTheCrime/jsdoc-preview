# JSDoc Preview package

Show the rendered HTML markdown to the right of the current editor using <kbd>ctrl-shift-d</kbd>.

It is currently enabled for `.js`, `.javascript`, and `.es6` files.

**NOTE:** This package will ignore all JSDoc plugins and themes defined in a custom `conf.json`

## Customize

By default, JSDoc Preview uses the default JSDoc stylesheets (minus the fonts). You can add your own css in the __package settings__ to make it look however you would like.

- [x] Custom Style Sheets

If you want to use a JSDoc theme, this is where you would add the stylesheets for the theme instead of defining it in `conf.json`.

**NOTE:** If you don't want to modify the other styles in your editor, wrap your custom styles in a `.jsdoc-preview` class.

You may also define your own JSDoc `conf.json` in __package_settings__:

- [x] Config File Path