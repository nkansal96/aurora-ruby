require 'test/unit'
require 'aurora-sdk'
require_relative '../test_helpers'

class ApiErrorTest < Test::Unit::TestCase
    include TestHelpers

    def test_nil_config
        Aurora::config = nil
        assert_raise( Aurora::NilConfigError ) { Aurora::get_interpret('what is the weather in los angeles?') }
    end

    def test_nil_id
        Aurora::config.app_id = nil
        assert_raise( Aurora::APIError ) { Aurora::get_interpret('what is the weather in los angeles?') }
    end

    def test_nil_token
        Aurora::config.app_token = nil
        assert_raise( Aurora::APIError ) { Aurora::get_interpret('what is the weather in los angeles?') }
    end
end
