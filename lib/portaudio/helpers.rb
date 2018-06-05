module Portaudio
    # Decide which libary to load based on OS
    def self.get_lib
        if Gem::Platform.local.os == "mingw32" && Gem::Platform.local.cpu == "x64"
            return File.absolute_path("lib/portaudio/binaries/libportaudio64bit.dll")
        elsif Gem::Platform.local.os == "mingw32" && Gem::Platform.local.cpu == "x86"
            return File.absolute_path("lib/portaudio/binaries/libportaudio32bit.dll")
        else
            return File.absolute_path("lib/portaudio/binaries/libportaudio.dylib")
        end
    end
end
