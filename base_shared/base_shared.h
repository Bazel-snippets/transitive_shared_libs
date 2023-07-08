#ifdef _MSC_VER
    #ifdef BUILD_BASE_SHARED
        #define EXPORT __declspec(dllexport)
    #else
        #define EXPORT __declspec(dllimport)
    #endif
#else
    #define EXPORT __attribute__((__visibility__("default")))
#endif

EXPORT unsigned int base_shared(void);
