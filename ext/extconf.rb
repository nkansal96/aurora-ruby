require 'mkmf'
$LIBS += ' -lportaudio'
create_makefile('portaudio')
