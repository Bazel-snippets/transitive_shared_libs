#include <ctime>
#include <string>
#include <iostream>
#include <wchar.h> // For wprintf

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <direct.h>
#define GetCurrentDir _getcwd
#else // _WIN32
#include <unistd.h>
#include <string.h>
#define GetCurrentDir getcwd
#endif // _WIN32

#include "middle_shared.h"

int main(int argc, char** argv, char * envp[]) {
  // printf("Environment:");
  // for (int i = 0; envp[i] != NULL; i++)
  //       printf("\n%s", envp[i]);
  // printf("\nEND of Environment.\n\n");

std::string who = "world";
if (argc > 1) {
    who = argv[1];
}

if (sizeof(void*) == 8) {
    printf("Bitness = 64\n");
}
if (sizeof(void*) == 4) {
    printf("Bitness = 32\n");
}

#ifdef _DEBUG
    printf("compilation_mode = _DEBUG\n");
#endif
#ifdef NDEBUG
    printf("compilation_mode = NDEBUG\n");
#endif

    unsigned int magic_number = middle_shared();
    printf("Magic number received from middle is %d.\n", magic_number);

    return 0;
}
