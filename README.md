# Aurora Ruby SDK
## Overview
Aurora is the enterprise end-to-end speech solution. This Ruby SDK will allow you to quickly and easily use the Aurora service to integrate voice capabilities into your application.

The SDK is currently in a pre-alpha release phase. Bugs and limited functionality should be expected.

## External Dependencies
- PortAudio (C/C++ API)
- Excon (Ruby gem)
- YARD (Ruby gem for documentation)

## Installation
**The Recommended Ruby version is 2.5.0+**

To install gem dependencies:
```
$ bundle install
```

To install PortAudio (or build and install from source):
```
$ brew install portaudio
```

To build and install the gem:
```
$ sudo rake install
```

Or, if you prefer to build and install manually:

```
$ gem build aurora-sdk.gemspec
$ sudo gem install aurora-sdk-x.x.x.gem
```

## Testing
The full test suite can be run using `rake`. To specify an individual test file, use the `TEST` option for rake:

```
$ rake TEST=./test/aurora/interpret_test.rb
```

## Documentation
The Aurora Ruby SDK uses YARD to generate documentation.
To generate documentation:

```
$ rake yard
```

This documentation will located in the `docs/app` directory.

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

The SDK will by default utilize one of the pre-compiled PortAudio binaries included in the source. However, if you want to
use a different binary (.dylib or .so), you can set an environment variable prior to requiring the SDK, like so:

```ruby
ENV['PA_PATH'] = '/path/to/libportaudio.dylib'
require 'aurora-sdk'
```

### Text to Speech (TTS)
```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

# Query the TTS service
speech  = Aurora::Text.new("Hello world").to_speech

# Play the resulting audio
speech.audio.play

# Or save it to a file
speech.audio.write_to_file("test.wav")
```

### Speech to Text (STT)

#### Convert a WAV file to Speech
```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

# Open an existing WAV file (16-bit, mono, 16kHz WAV PCM)
file = File.open("test.wav", "rb")
audio_file = Aurora::AudioFile.new(file.read)
text_object = Aurora::Speech.new(audio_file).to_text
puts text_object.text
file.close
```

#### Convert a previous Text API call to Speech
```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

# Call the TTS API to convert "Hello world" to speech
speech = Aurora::Text.new("Hello world").to_speech

# Previous API call returned a Speech object, so we can just call
# the to_text method to get a prediction
prediction = speech.to_text
puts prediction.text
```

### Listening

#### Listen for a specified amount of time
```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

# Listen for 3 seconds
speech = Aurora.listen(3)

# Convert to text
t = speech.to_text
puts t.text
```

#### Listen for an unspecified amount of time
```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

# Start listening until 1.0s of silence
speech = Aurora.listen
# Or specify you own silence timeout (2.0s shown here)
speech = Aurora.listen(0,2)

# Convert to text
t = speech.to_text
puts t.text
```

#### Continuously listen

Continuously listen and retrieve speech segments. Note: You can do anything with these speech segments, but here we'll convert them
to text. Just like the previous example, these segments are demarcated by silence (1.0 second by default) and can be changed by
setting the first parameter to 0 and the second to the desired silence length. Additionally, you can make these segments fixed in length
by passing in a first parameter with a positive, non-zero value.

```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

# Continuously listen and convert to speech (blocking example)
Aurora.continuously_listen.each do |speech|
    t = speech.to_text
    puts t.text
end

# Reduce the amount of silence in between speech segments
Aurora.continuously_listen(0,0.5).each do |speech|
    t = speech.to_text
    puts t.text
end

# Fixed-length speech segments of 3 seconds
Aurora.continuously_listen(3).each do |speech|
    t = speech.to_text
    puts t.text
end
```

#### Listen and transcribe
If you already know that you wanted the recorded speech to be converted to text, you can do it in one step, reducing the amount of
code you need to write and also reducing latency. Using the ```listen_and_transcribe``` method, the audio that is recorded automatically
starts uploading as soon as you call the method and transcription begins. When the audio recording ends, you get back the final transcription.

```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

t = Aurora.listen_and_transcribe(0,0.5)
puts t.text

# You can also use this in the same way as 'continuously_listen'
Aurora.continuously_listen_and_transcribe(0,0.5).each do |t|
    puts t.text
end
```

### Interpret (Language Understanding)
The interpret service allows you to take any Aurora `Text` object and extract the user's intent and additional query information. The function `to_interpret` returns an `Interpret` object, and is only available for `Text` objects. To convert speech into an `Interpret` object, it must be converted into text first.

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

#### Smart Lamp

This example shows how easy it is to voice-enable a smart lamp. It responds to queries in the form of "turn on the lights" or "turn off the lamp." You define what ```object``` you are listening for (so that you can ignore queries like "turn on the music").

```ruby
# Import the package
require 'aurora-sdk'

# Set your application settings
Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)

valid_entities = ["light", "lights", "lamp"]

# Continuously listen and convert to speech (blocking example)
Aurora.continuously_listen(0,0.5).each do |speech|
    i = speech.to_text.to_interpret

    if i.intent == "turn_on"
        i.entities.each do |e|
            if valid_entities.include? e
                # do something to turn on lamp
                break
            end
        end
    elsif i.intent == "turn_off"
        i.entities.each do |e|
            if valid_entities.include? e
                # do something to turn off lamp
                break
            end
        end
    end
end
```