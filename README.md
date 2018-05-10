# Aurora Ruby SDK
## Overview
Aurora is the enterprise end-to-end speech solution. This Ruby SDK will allow you to quickly and easily use the Aurora service to integrate voice capabilities into your application.

The SDK is currently in a pre-alpha release phase. Bugs and limited functionality should be expected.

## Installation
**The Recommended Ruby version is 2.5.0+**

To build and install:

```
$ sudo rake install
```

Or, if you prefer to build and install manually:

```
$ gem build aurora-sdk.gemspec
$ sudo gem install aurora-sdk-x.x.x.gem
```

## Testing
The full test suite can be run using `rake`.


To specify an individual test file, use the `TEST` option for rake. Example: `rake TEST=./test/aurora/interpet_test.rb`
