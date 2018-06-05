#include <stdio.h>
#include <dlfcn.h>
#include <portaudio.h>

int main(void) {
    Dl_info info;
    if (dladdr(Pa_GetVersion, &info)) {
        printf("%s", info.dli_fname);
        return 1;
    }
    else {
        return 0;
    }
}
