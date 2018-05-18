# Aurora Ruby SDK
## Overview
Aurora is the enterprise end-to-end speech solution. This Ruby SDK will allow you to quickly and easily use the Aurora service to integrate voice capabilities into your application.

The SDK is currently in a pre-alpha release phase. Bugs and limited functionality should be expected.

## Prerequisites
- Ruby (2.5.0+)
- Swig
- PortAudio

## Installation
**The Recommended Ruby version is 2.5.0+**

To build and install the gem:

```
$ sudo rake install
```

Or, if you prefer to build and install manually:

```
$ gem build aurora-sdk.gemspec
$ sudo gem install aurora-sdk-x.x.x.gem
```

To build and install PortAudio bindings for Ruby:
```
$ rake build_pa
```

Simple running `rake install` will build and install the bindings, as well.

## Testing
The full test suite can be run using `rake`. To specify an individual test file, use the `TEST` option for rake:

```
$ rake TEST=./test/aurora/interpret_test.rb
```

## Basic Usage

First, make sure you have an account with [Aurora](http://dashboard.auroraapi.com/) and have created an Application.

### Configuration

```ruby
require 'aurora-sdk'

# Set your application settings.
# APP_ID and APP_TOKEN are required. DEVICE_ID is optional
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

puts Aurora.config.app_id
puts Aurora.config.app_token
puts Aurora.config.device_id
```


### Interpret (Language Understanding)
The interpret service allows you to take any Aurora `Text` object and extract the user's intent and additional query information. The function `to_interpret` returns an `Interpret` object, and is only available for `Text` objects. To convert speech into an `Interpret` object, it must be converted into text first.

#### Basic Example
```ruby
require 'aurora-sdk'

# Create a Text object
text = Aurora::Text.new("what is the time in los angeles")

# Call the interpret service. This returns an `Interpret` object.
i = text.to_interpret

# Get the user's intent
puts i.intent               # "time"

# Get any additional information
puts i.entities             # {"location"=>"los angeles"}
```

#### User Query Example
```ruby
require 'aurora-sdk'

while true
    # Repeatedly ask the user to enter a command
    print 'Enter a command: '
    user_text = gets.chomp
    if user_text == 'quit'
        break
    end

    # Interpret and print the result
    i = Aurora::Text.new(user_text).to_interpret
    puts i.intent
    puts i.entities
end
```
