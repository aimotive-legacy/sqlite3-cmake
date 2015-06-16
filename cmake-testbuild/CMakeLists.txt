cmake_minimum_required(VERSION 3.1)
project(cmake-testbuild)

find_package(sqlite3 REQUIRED)
add_executable(sqlite3-test ../shell.c)
target_link_libraries(sqlite3-test sqlite3)
install(TARGETS sqlite3-test DESTINATION bin)
