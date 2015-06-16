# sqlite3-cmake
cmake build of the sqlite3 amalgamation using the autoconf release as reference

Provides a config-module which can be used like this:

    find_package(sqlite3 REQUIRED)
    target_link_libraries(<my-target> sqlite3)
