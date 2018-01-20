set(_sqlite3_SEARCHES)

if (sqlite3_ROOT)
  set(_sqlite3_SEARCH_ROOT PATHS ${sqlite3_ROOT} NO_DEFAULT_PATH)
  list(APPEND _sqlite3_SEARCHES _sqlite3_SEARCH_ROOT)
endif()
list(APPEND _sqlite3_SEARCHES " ")

set(sqlite3_NAMES sqlite3)
set(sqlite3_NAMES_DEBUG sqlite3d)

find_path(sqlite3_INCLUDE_DIR NAMES sqlite3.h)

# Allow sqlite3_LIBRARY to be set manually, as the location of the sqlite3 library
if(NOT sqlite3_LIBRARY)
  foreach(search ${_sqlite3_SEARCHES})
    find_library(sqlite3_LIBRARY_RELEASE NAMES ${sqlite3_NAMES} ${${search}} PATH_SUFFIXES lib)
    find_library(sqlite3_LIBRARY_DEBUG NAMES ${sqlite3_NAMES_DEBUG} ${${search}} PATH_SUFFIXES lib)
  endforeach()
  if (sqlite3_LIBRARY_RELEASE)
    list(APPEND sqlite3_LIBRARY optimized ${sqlite3_LIBRARY_RELEASE})
  endif()
  if (sqlite3_LIBRARY_DEBUG)
    list(APPEND sqlite3_LIBRARY debug ${sqlite3_LIBRARY_DEBUG})
  endif()
endif()

unset(sqlite3_NAMES)
unset(sqlite3_NAMES_DEBUG)

mark_as_advanced(sqlite3_INCLUDE_DIR)

if(sqlite3_INCLUDE_DIR AND EXISTS "${sqlite3_INCLUDE_DIR}/sqlite3.h")
    file(STRINGS "${sqlite3_INCLUDE_DIR}/sqlite3.h" sqlite3_H REGEX "^#define SQLITE_VERSION[ ]+\"[^\"]*\"$")

    string(REGEX REPLACE "^.*SQLITE_VERSION[ ]+\"([0-9]+).*$" "\\1" sqlite3_VERSION_MAJOR "${sqlite3_H}")
    string(REGEX REPLACE "^.*SQLITE_VERSION[ ]+\"[0-9]+\\.([0-9]+).*$" "\\1" sqlite3_VERSION_MINOR  "${sqlite3_H}")
    string(REGEX REPLACE "^.*SQLITE_VERSION[ ]+\"[0-9]+\\.[0-9]+\\.([0-9]+).*$" "\\1" sqlite3_VERSION_PATCH "${sqlite3_H}")
    set(sqlite3_VERSION_STRING "${sqlite3_VERSION_MAJOR}.${sqlite3_VERSION_MINOR}.${sqlite3_VERSION_PATCH}")

    # only append a TWEAK version if it exists:
    set(sqlite3_VERSION_TWEAK "")
    if( "${sqlite3_H}" MATCHES "sqlite3_VERSION \"[0-9]+\\.[0-9]+\\.[0-9]+\\.([0-9]+)")
        set(sqlite3_VERSION_TWEAK "${CMAKE_MATCH_1}")
        string(APPEND sqlite3_VERSION_STRING ".${sqlite3_VERSION_TWEAK}")
    endif()

    set(sqlite3_MAJOR_VERSION "${sqlite3_VERSION_MAJOR}")
    set(sqlite3_MINOR_VERSION "${sqlite3_VERSION_MINOR}")
    set(sqlite3_PATCH_VERSION "${sqlite3_VERSION_PATCH}")
endif()

# handle the QUIETLY and REQUIRED arguments and set sqlite3_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(sqlite3 REQUIRED_VARS sqlite3_LIBRARY sqlite3_INCLUDE_DIR
                                       VERSION_VAR sqlite3_VERSION_STRING)

if(sqlite3_FOUND)
    set(sqlite3_INCLUDE_DIRS ${sqlite3_INCLUDE_DIR})

    if(NOT sqlite3_LIBRARIES)
      set(sqlite3_LIBRARIES ${sqlite3_LIBRARY})
    endif()

    if(NOT TARGET sqlite3)
      add_library(sqlite3 UNKNOWN IMPORTED)
      set_target_properties(sqlite3 PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${sqlite3_INCLUDE_DIRS}")

      if(sqlite3_LIBRARY_RELEASE)
        set_property(TARGET sqlite3 APPEND PROPERTY
          IMPORTED_CONFIGURATIONS RELEASE)
        set_target_properties(sqlite3 PROPERTIES
          IMPORTED_LOCATION_RELEASE "${sqlite3_LIBRARY_RELEASE}")
      endif()

      if(sqlite3_LIBRARY_DEBUG)
        set_property(TARGET sqlite3 APPEND PROPERTY
          IMPORTED_CONFIGURATIONS DEBUG)
        set_target_properties(sqlite3 PROPERTIES
          IMPORTED_LOCATION_DEBUG "${sqlite3_LIBRARY_DEBUG}")
      endif()

      if(NOT sqlite3_LIBRARY_RELEASE AND NOT sqlite3_LIBRARY_DEBUG)
        set_property(TARGET sqlite3 APPEND PROPERTY
          IMPORTED_LOCATION "${sqlite3_LIBRARY}")
      endif()
    endif()
endif()
