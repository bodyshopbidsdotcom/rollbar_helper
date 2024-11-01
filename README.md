# RollbarHelper

When you call `Rollbar.error('description')`, rollbar doesn't provide a stacktrace, just the "description" error. To find exactly where this error was generated, one has to search the entire codebase for `"description"`.

This gem allows you to call `RollbarHelper.error('description')` and get a stacktrace on https://rollbar.com pointing where in the code it was exactly generated.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rollbar_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rollbar_helper

## Usage

Instead of calling `Rollbar.error(...)`, call
```ruby
RollbarHelper.error(*args)
```


`args` will be an array that can include a mix of:
- a String for the message to show
- an Exception
- an hash for extra params to be sent to Rollbar, including:
  - `:fingerprint` for grouping
  - `:e` for providing an Exception (to not break legacy code)

Example:
```ruby
RollbarHelper.error(
  'Something went wrong',
  exception,
  { foo: 'bar' }
)
```

ℹ️ Rollbar allows receiving the args in any given order and it will ignore when an arg not a String, Hash or Exception.

## Development

### Setup
After checking out the repo, run `bin/setup` to install dependencies.

### Specs
Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Install
To install this gem onto your local machine, run `bundle exec rake install`.

### Release
To release a new version:
- update the version number in `version.rb`,
- run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bodyshopbidsdotcom/rollbar_helper.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

