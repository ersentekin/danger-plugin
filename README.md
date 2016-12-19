# danger-code_style_validation

This plugin looks for code style violations for added lines and suggests patches.

It uses 'clang-format' and only checks `.h`, `.m` and `.mm` files

## Installation

```
$ gem install danger-code_style_validation
```

## Usage

Inside your `Dangerfile` :

```
code_style_validation.check
```

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
