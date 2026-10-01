# Homebrew's sdl2-compat loads SDL3 dynamically. BundleUtilities cannot discover
# this dependency with otool, so install it next to SDL2 before signing the app.
if(APPLE)
    find_package(SDL2 CONFIG REQUIRED)
    get_filename_component(_oot_sdl2_package "${SDL2_DIR}" REALPATH)
    if(_oot_sdl2_package MATCHES "/sdl2-compat/")
        find_library(OOT_SDL3_LIBRARY NAMES SDL3 REQUIRED)
        get_filename_component(_oot_sdl3_library "${OOT_SDL3_LIBRARY}" REALPATH)
        install(FILES "${_oot_sdl3_library}" DESTINATION ../Frameworks
                RENAME libSDL3.dylib COMPONENT ship)
    endif()
endif()
