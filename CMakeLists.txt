cmake_minimum_required(VERSION 3.0)
project(sqlite3)

# todo: readline support for sqlite3/shell.c
#todo: STRERROR_R_CHAR_P

option(SQLITE_ENABLE_THREADSAFE "build a thread-safe library, default = ON" ON)
option(SQLITE_ENABLE_DYNAMIC_EXTENSIONS "support loadable extensions, default = ON" ON)
option(SQLITE_ENABLE_FTS3 "version 3 of the full-text search engine, see also SQLITE_ENABLE_FTS4 which enables FTS3 as well, default = OFF" OFF)
option(SQLITE_ENABLE_FTS3_PARENTHESIS "modifies the query pattern parser in FTS3 such that it supports operators AND and NOT and also allows query expressions to contain nested parenthesis, default = OFF" OFF)
option(SQLITE_ENABLE_FTS4 "versions 3 and 4 of the full-text search engine, default = ON" ON)
option(SQLITE_ENABLE_RTREE "include support for the R*Tree index extension" ON)
option(SQLITE_ENABLE_COLUMN_METADATA "include APIs that provide access to meta-data about tables and queries, default = ON" ON)
option(BUILD_SHARED_LIBS "" OFF)
option(SQLITE_BUILD_LIB "Build libsqlite3, default = ON" ON)
option(SQLITE_BUILD_SHELL "Build the sqlite3 shell, default = ON" ON)

if(SQLITE_BUILD_LIB)
    # library output name
    if(UNIX OR BUILD_SHARED_LIBS)
        set(output_name sqlite3)
    else()
        set(output_name libsqlite3)
    endif()

    file(STRINGS sqlite3.h version REGEX "#define[ \t]+SQLITE_VERSION[ \t]+\".+\"")
    string(REGEX MATCH "[0-9.]+" version "${version}" "")
    string(REGEX MATCH "^[0-9]+" version_major "${version}")
    if(NOT version_major)
        message(FATAL_ERROR "Version number parsing failed, please check sqlite3.h and parsing code here")
    endif()

    include(CheckFunctionExists)
    include(CheckIncludeFiles)
    include(CheckTypeSize)
    include(CheckSymbolExists)

    set(definitions "")
    foreach(c posix_fallocate fdatasync usleep localtime_r gmtime_r malloc_usable_size strchrnul strerror_r utime)
        string(TOUPPER "HAVE_${c}" huc)
        check_function_exists(${c} ${huc})
        if(${huc})
            list(APPEND definitions "${huc}=1")
        endif()
    endforeach()

    check_symbol_exists(localtime_s time.h HAVE_LOCALTIME_S)
    check_symbol_exists(isnan math.h HAVE_ISNAN)

    foreach(c inttypes malloc stdint)
        string(TOUPPER "HAVE_${c}_H" huc)
        check_include_files(${c}.h ${huc})
        if(${huc})
            list(APPEND definitions "${huc}=1")
        endif()
    endforeach()

    foreach(c int8_t int16_t uint8_t uint16_t uint32_t)
        string(TOUPPER "${c}" huc)
        check_type_size(${c} ${huc})
        if(HAVE_${huc})
            list(APPEND definitions "HAVE_${huc}=1")
        endif()
    endforeach()

    add_library(sqlite3 sqlite3.c sqlite3.h sqlite3ext.h)

    # handle options
    if(SQLITE_ENABLE_THREADSAFE)
         # configure.ac defines _REENTRANT=1 which is for tea/Solaris
         # we omit this here, it's used only there
        target_compile_definitions(sqlite3 PUBLIC SQLITE_THREADSAFE=1)
        set(CMAKE_THREAD_PREFER_PTHREAD 1)
        set(THREADS_PREFER_PTHREAD_FLAG)
        include(FindThreads)
        if(THREADS_FOUND)
            if(NOT TARGET Threads::Threads)
                add_library(Threads::Threads INTERFACE IMPORTED)
                if(THREADS_HAVE_PTHREAD_ARG)
                    set_property(TARGET Threads::Threads PROPERTY INTERFACE_COMPILE_OPTIONS "-pthread")
                endif()
                if(CMAKE_THREAD_LIBS_INIT)
                    set_property(TARGET Threads::Threads PROPERTY INTERFACE_LINK_LIBRARIES "${CMAKE_THREAD_LIBS_INIT}")
                endif()
            endif()
            target_link_libraries(sqlite3 PRIVATE Threads::Threads)
            set(needs_threads 1)
        endif()
    else()
        target_compile_definitions(sqlite3 PUBLIC SQLITE_THREADSAFE=0)
    endif()

    if(SQLITE_ENABLE_DYNAMIC_EXTENSIONS AND CMAKE_DL_LIBS)
        add_library(sqlite3::dl INTERFACE IMPORTED)
        set_property(TARGET sqlite3::dl PROPERTY INTERFACE_LINK_LIBRARIES "${CMAKE_DL_LIBS}")
        target_link_libraries(sqlite3 PRIVATE sqlite3::dl)
        set(needs_dl 1)
    else()
        target_compile_definitions(sqlite3 PUBLIC SQLITE_OMIT_LOAD_EXTENSION=1)
    endif()

    # set other properties
    set_target_properties(sqlite3 PROPERTIES
        OUTPUT_NAME ${output_name}
        DEBUG_POSTFIX d)
    if(UNIX)
        set_target_properties(sqlite3 PROPERTIES
            VERSION 0.8.6.8
            SOVERSION 0)
    else()
        set_target_properties(sqlite3 PROPERTIES
            VERSION ${version})
    endif()

    if(BUILD_SHARED_LIBS)
        if(MSVC)
            target_compile_definitions(sqlite3
                PRIVATE "SQLITE_API=__declspec(dllexport)"
                INTERFACE "SQLITE_API=__declspec(dllimport)")
        endif()
    endif()

    foreach(c SQLITE_ENABLE_FTS3 SQLITE_ENABLE_FTS3_PARENTHESIS SQLITE_ENABLE_FTS4 SQLITE_ENABLE_RTREE SQLITE_ENABLE_COLUMN_METADATA)
        if(${c})
            target_compile_definitions(sqlite3 PUBLIC ${c})
        endif()
    endforeach()

    target_include_directories(sqlite3 PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>)

    install(TARGETS sqlite3 EXPORT sqlite3-targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        )

    install(EXPORT sqlite3-targets DESTINATION lib/cmake/sqlite3)

    set(config_module "")

    if(NOT BUILD_SHARED_LIBS)
        if(needs_threads)
            set(config_module "${config_module}
                if(NOT THREADS_FOUND)
                    set(CMAKE_THREAD_PREFER_PTHREAD 1)
                    set(THREADS_PREFER_PTHREAD_FLAG)
                    include(FindThreads)
                endif()
                if(THREADS_FOUND)
                    if(NOT TARGET Threads::Threads)
                        add_library(Threads::Threads INTERFACE IMPORTED)
                        if(THREADS_HAVE_PTHREAD_ARG)
                            set_property(TARGET Threads::Threads PROPERTY INTERFACE_COMPILE_OPTIONS \"-pthread\")
                        endif()
                        if(CMAKE_THREAD_LIBS_INIT)
                            set_property(TARGET Threads::Threads PROPERTY INTERFACE_LINK_LIBRARIES \"\${CMAKE_THREAD_LIBS_INIT}\")
                        endif()
                    endif()
                else()
                    message(FATAL_ERROR \"Threads not found.\")
                endif()
            ")
        endif()
        if(needs_dl)
            set(config_module "${config_module}
                if(NOT TARGET sqlite3::dl)
                  add_library(sqlite3::dl INTERFACE IMPORTED)
                  set_property(TARGET sqlite3::dl PROPERTY INTERFACE_LINK_LIBRARIES \"\${CMAKE_DL_LIBS}\")
                endif()
                ")
        endif()
    endif()

    set(config_module "${config_module}
        include(\${CMAKE_CURRENT_LIST_DIR}/sqlite3-targets.cmake)
        ")
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/hide/sqlite3-config.cmake "${config_module}")

    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/hide/sqlite3-config.cmake DESTINATION lib/cmake/sqlite3)
    install(FILES sqlite3.h sqlite3ext.h DESTINATION include)
endif()

if(SQLITE_BUILD_SHELL)
    if(NOT TARGET sqlite3)
        find_package(sqlite3 REQUIRED)
    endif()

    add_executable(shell shell.c)
    set_target_properties(shell PROPERTIES
        OUTPUT_NAME sqlite3
        DEBUG_POSTFIX d)
    target_link_libraries(shell sqlite3)
    install(TARGETS shell DESTINATION bin)
endif()

