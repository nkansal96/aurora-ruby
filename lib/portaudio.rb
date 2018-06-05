require 'fiddle'
require 'fiddle/import'
require_relative 'portaudio/find_lib'

module Portaudio
  extend Fiddle::Importer

  dlload find_lib

  # Custom typedefs
  typealias 'PaError', 'int'
  typealias 'PaErrorCode', 'int'
  typealias 'PaDeviceIndex', 'int'
  typealias 'PaHostApiIndex', 'int'
  typealias 'PaHostApiTypeId', 'int'
  typealias 'PaTime', 'double'
  typealias 'PaSampleFormat', 'unsigned long'
  typealias 'PaStreamFlags', 'unsigned long'
  typealias 'PaStream', 'void'
  typealias 'PaSteamFlags', 'unsigned long'
  typealias 'PaStreamCallbackFlags', 'unsigned long'
  typealias 'PaStreamCallbackResult', 'int'
  typealias 'PaStreamCallback(
      const void *input, void *output,
      unsigned long frameCount,
      const PaStreamCallbackTimeInfo* timeInfo,
      PaStreamCallbackFlags statusFlags,
      void *userData )', 'PaStreamCallback'
  typealias 'PaStreamFinishedCallback( void *userData )', 'void'

  # Custom structs
  PaVersionInfo = struct [
    'int versionMajor',
    'int versionMinor',
    'int versionSubMinor',
    'const char *versionControlRevision',
    'const char *versionText'
  ]

  PaHostApiInfo = struct [
    'int structVersion',
    'PaHostApiTypeId type',
    'const char *name',
    'int deviceCount',
    'PaDeviceIndex defaultInputDevice',
    'PaDeviceIndex defaultOutputDevice'
  ]

  PaHostErrorInfo = struct [
    'PaHostApiTypeId hostApiType',
    'long errorCode',
    'const char *errorText'
  ]

  PaDeviceInfo = struct [
    'int structVersion',
    'const char *name',
    'PaHostApiIndex hostApi',
    'int maxInputChannels',
    'int maxOutputChannels',
    'PaTime defaultLowInputLatency',
    'PaTime defaultLowOutputLatency',
    'PaTime defaultHighInputLatency',
    'PaTime defaultHighOutputLatency',
    'double defaultSampleRate'
  ]

  PaStreamParameters = struct [
    'PaDeviceIndex device',
    'int channelCount',
    'PaSampleFormat sampleFormat',
    'PaTime suggestedLatency',
    'void *hostApiSpecificStreamInfo'
  ]

  PaStreamCallbackTimeInfo = struct [
    'PaTime inputBufferAdcTime',
    'PaTime currentTime',
    'PaTime outputBufferDacTime'
  ]

  PaStreamInfo = struct [
    'int structVersion',
    'PaTime inputLatency',
    'PaTime outputLatency',
    'double sampleRate'
  ]

  # Nested modules for constant enums
  module PaErrorCode
    PaNoError                               = 0
    PaNotInitialized                        = -10000
    PaUnanticipatedHostError                = -9999
    PaInvalidChannelCount                   = -9998
    PaInvalidSampleRate                     = -9997
    PaInvalidDevice                         = -9996
    PaInvalidFlag                           = -9995
    PaSampleFormatNotSupported              = -9994
    PaBadIODeviceCombination                = -9993
    PaInsufficientMemory                    = -9992
    PaBufferTooBig                          = -9991
    PaBufferTooSmall                        = -9990
    PaNullCallback                          = -9989
    PaBadStreamPtr                          = -9988
    PaTimedOut                              = -9987
    PaInternalError                         = -9986
    PaDeviceUnavailable                     = -9985
    PaIncompatibleHostApiSpecificStreamInfo = -9984
    PaStreamIsStopped                       = -9983
    PaStreamIsNotStopped                    = -9982
    PaInputOverflowed                       = -9981
    PaOutputUnderflowed                     = -9980
    PaHostApiNotFound                       = -9979
    PaInvalidHostApi                        = -9978
    PaCanNotReadFromACallbackStream         = -9977
    PaCanNotWriteToACallbackStream          = -9976
    PaCanNotReadFromAnOutputOnlyStream      = -9975
    PaCanNotWriteToAnInputOnlyStream        = -9974
    PaIncompatibleStreamHostApi             = -9973
    PaBadBufferPtr                          = -9972
  end

  module PaHostApiTypeId
    PaInDevelopment   = 0
    PaDirectSound     = 1
    PaMME             = 2
    PaASIO            = 3
    PaSoundManager    = 4
    PaCoreAudio       = 5
    PaOSS             = 7
    PaALSA            = 8
    PaAL              = 9
    PaBeOS            = 10
    PaWDMKS           = 11
    PaJACK            = 12
    PaWASAPI          = 13
    PaAudioScienceHPI = 14
  end

  module PaStreamCallbackResult
    PaContinue = 0
    PaComplete = 1
    PaAbort    = 2
  end

  # Miscellaneous #define'd constants
  PaNoDevice                              = -1
  PaUseHostApiSpecificDeviceSpecification = -2

  # PaSampleFormats
  PaFloat32                               = 0x00000001
  PaInt32                                 = 0x00000002
  PaInt24                                 = 0x00000004
  PaInt16                                 = 0x00000008
  PaInt8                                  = 0x00000010
  PaUInt8                                 = 0x00000020
  PaCustomFormat                          = 0x00010000
  PaNonInterleaved                        = 0x80000000

  PaFormatIsSupported                     = 0
  PaFramesPerBufferUnspecified            = 0

  # PaStreamFlags
  PaNoFlag                                = 0
  PaClipOff                               = 0x00000001
  PaDitherOff                             = 0x00000002
  PaNeverDropInput                        = 0x00000004
  PaPrimeOutputBuffersUsingStreamCallback = 0x00000008
  PaPlatformSpecificFlags                 = 0xFFFF0000

  # PaStreamCallbackFlags
  PaInputUnderflow                        = 0x00000001
  PaInputOverflow                         = 0x00000002
  PaOutputUnderflow                       = 0x00000004
  PaOutputOverflow                        = 0x00000008
  PaPrimingOutput                         = 0x00000010

  # Function signatures
  extern 'int Pa_GetVersion( void )'
  extern 'const char* Pa_GetVersionText( void )'
  extern 'const PaVersionInfo* Pa_GetVersionInfo( void )'
  extern 'const char *Pa_GetErrorText( PaError errorCode )'
  extern 'PaError Pa_Initialize( void )'
  extern 'PaError Pa_Terminate( void )'
  extern 'PaHostApiIndex Pa_GetHostApiCount( void )'
  extern 'PaHostApiIndex Pa_GetDefaultHostApi( void )'
  extern 'const PaHostApiInfo * Pa_GetHostApiInfo( PaHostApiIndex hostApi )'
  extern 'PaHostApiIndex Pa_HostApiTypeIdToHostApiIndex( PaHostApiTypeId type )'
  extern 'PaDeviceIndex Pa_HostApiDeviceIndexToDeviceIndex( PaHostApiIndex hostApi, int hostApiDeviceIndex )'
  extern 'const PaHostErrorInfo* Pa_GetLastHostErrorInfo( void )'
  extern 'PaDeviceIndex Pa_GetDeviceCount( void )'
  extern 'PaDeviceIndex Pa_GetDefaultInputDevice( void )'
  extern 'PaDeviceIndex Pa_GetDefaultOutputDevice( void )'
  extern 'const PaDeviceInfo* Pa_GetDeviceInfo( PaDeviceIndex device )'
  extern 'PaError Pa_IsFormatSupported( const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters, double sampleRate )'
  extern 'PaError Pa_OpenStream( PaStream** stream, const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters, double sampleRate, unsigned long framesPerBuffer, PaStreamFlags streamFlags, PaStreamCallback *streamCallback, void *userData )'
  extern 'PaError Pa_OpenDefaultStream( PaStream** stream, int numInputChannels, int numOutputChannels, PaSampleFormat sampleFormat, double sampleRate, unsigned long framesPerBuffer, PaStreamCallback *streamCallback, void *userData )'
  extern 'PaError Pa_CloseStream( PaStream *stream )'
  extern 'PaError Pa_SetStreamFinishedCallback( PaStream *stream, PaStreamFinishedCallback* streamFinishedCallback )'
  extern 'PaError Pa_StartStream( PaStream *stream )'
  extern 'PaError Pa_StopStream( PaStream *stream )'
  extern 'PaError Pa_AbortStream( PaStream *stream )'
  extern 'PaError Pa_IsStreamStopped( PaStream *stream )'
  extern 'PaError Pa_IsStreamActive( PaStream *stream )'
  extern 'const PaStreamInfo* Pa_GetStreamInfo( PaStream *stream )'
  extern 'PaTime Pa_GetStreamTime( PaStream *stream )'
  extern 'double Pa_GetStreamCpuLoad( PaStream* stream )'
  extern 'PaError Pa_ReadStream( PaStream* stream, void *buffer, unsigned long frames )'
  extern 'PaError Pa_WriteStream( PaStream* stream, const void *buffer, unsigned long frames )'
  extern 'signed long Pa_GetStreamReadAvailable( PaStream* stream )'
  extern 'signed long Pa_GetStreamWriteAvailable( PaStream* stream )'
  extern 'PaError Pa_GetSampleSize( PaSampleFormat format )'
  extern 'void Pa_Sleep( long msec )'
end
