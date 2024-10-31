# RollbarHelper

When calling `Rollbar.error('description')`, rollbar doesn't provide a stacktrace, just the "description" error. To find exactly where this error was generated, one has to search the entire codebase for `"description"`.

This gem allows you to call `RollbarHelper.error('description')` and get a stacktrace on https://rollbar.com pointing where in the code it was exactly generated.

## Installation

⚠️ `RollbarHelper` is now published via Package Registry and not RubyGems anymore. Please update your Gemfile accordingly!

Add this line to your application's Gemfile:

```ruby
source 'https://rubygems.pkg.github.com/bodyshopbidsdotcom' do
  gem 'rollbar_helper'
end
```

And then execute:

    $ bundle


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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Building/Publishing New Version

First, insure you have everything setup to publish gems. Directions can be found [in this confluence page](https://snapsheettech.atlassian.net/wiki/spaces/TECH/pages/270467413/Use+Github+Package+Registry+For+Internal+Ruby+Gems).

To release a new version, update the `RollbarHelper::VERSION` version number in `version.rb`.

Then run `gem build rollbar_helper.gemspec` to ensure it builds, then commit the version.

Create and push tags:

    $ git tag -a v{version} -m "Release {version}"
    $ git push origin v{version}


Example:

    $ git tag -a v1.0.0 -m "Release 1.0.0"
    $ git push origin v1.0.0

Finally, publish the new version to the Github Package Registry (see https://snapsheettech.atlassian.net/wiki/spaces/TECH/pages/149946563/Github+Package+Registry):

    $ gem push --key github --host https://rubygems.pkg.github.com/bodyshopbidsdotcom rollbar_helper-<VERSION>.gem


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bodyshopbidsdotcom/rollbar_helper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

