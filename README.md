# Envoy

Bringing peace to the SQS Messaging world, way better than Rabbit!

## Features

- Celluloid based Actor framework for building queue consumers
- Robust message handling, invisibility timeout handling, and pushback if messages failed
- Hooks into the message lifecycle
- Custom actors can be inserted into the main application loop, so you can execute other custom functionality, all in the same process

## Installation

Add the gem into your Gemfile
```ruby
gem 'envoy', github: 'musicglue/envoy'
```

Then Bundle

## Configuration

### Rails

If you are using this within a Rails applicaion Envoy comes with a handy generator to install an example configuration file

    $ rails g envoy:initializer

This will place a configuration file within the initializers directory, please follow the instructions there in order to configure Envoy.

### Standalone (Untested)

If you want to use this standalone, this behaviour is currently untested, however you should be able to create a configuration file, and then point the executable at it when running

```ruby
Envoy.configure do |config|
    
    config.aws.... # ETC

end
```

## Usage

To boot envoy, simply switch into the directory in question, and run

    $ bundle exec envoy

If you need to pass in a configuration file, such as in the standalone scenario, you'll need to do

    $ bundle exec envoy -r path/to/file.rb
    

## Contributing

1. Fork it ( https://github.com/[my-github-username]/envoy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
