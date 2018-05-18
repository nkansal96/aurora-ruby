%module portaudio
%{
  #include <portaudio.h>
%}

%rename("%(strip:[Pa_])s") "";
%include "/usr/local/include/portaudio.h"
