#ifdef _MSC_VER
    #ifdef BUILD_MIDDLE_SHARED
        #define EXPORT __declspec(dllexport)
    #else
        #define EXPORT __declspec(dllimport)
    #endif
#else
    #define EXPORT __attribute__((__visibility__("default")))
#endif

EXPORT unsigned int middle_shared(void);
