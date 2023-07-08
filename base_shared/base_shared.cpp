#include <stdio.h>

#include "base_shared.h"

unsigned int base_shared()
{
    printf("Shared library successfully invoked.\n");
    return 42;
}
