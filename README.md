# Duckly

Duckly is Ruby gem and library that enables developers to interact with D.Labs Duck

## Installation

Add this line to your application's Gemfile:

    gem 'duckly'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install duckly

## Developement

Create .env file with following settings

    DUCK_UID=your.username@dlabs.si
    DUCK_PWD=... you password ...

Run RSpec. First time you run RSpec, VCR will record interaction with API in your behalf.
So that next time you'll run it developement process will be faster and more efficient

    rspec

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
