module Portaudio
    # Decide which libary to load based on OS
    def self.get_lib
        if ENV.has_key?("PA_PATH") && File.exist?(File.expand_path(ENV["PA_PATH"]))
            return File.expand_path(ENV["PA_PATH"])
        end

        if Gem::Platform.local.os == "mingw32" && Gem::Platform.local.cpu == "x64"
            return File.join(File.dirname(__FILE__), '/binaries/libportaudio64bit.dll')
        elsif Gem::Platform.local.os == "mingw32" && Gem::Platform.local.cpu == "x86"
            return File.join(File.dirname(__FILE__), '/binaries/libportaudio32bit.dll')
        elsif Gem::Platform.local.os == "linux"
            return File.join(File.dirname(__FILE__), '/binaries/libportaudio.so')
        else
            return File.join(File.dirname(__FILE__), '/binaries/libportaudio.dylib')
        end
    end
end
