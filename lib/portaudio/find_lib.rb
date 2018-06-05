require 'fileutils'
require_relative '../aurora-sdk/error'

def find_lib
    lib_path = nil

    FileUtils.remove_dir('build', true)
    Dir.mkdir('build')

    Dir.chdir('build') do
        %x( cmake ../lib/portaudio )
        %x( make >/dev/null 2>&1 )
        lib_path = %x( ./findLib )
    end

    FileUtils.remove_dir('build', true)

    return lib_path if !lib_path.nil?
    raise Aurora::PortAudioError.new('PortAudio is not installed correctly.')
end
