cmake_minimum_required (VERSION 3.5)
project (findLib)
set (CMAKE_C_FLAGS "-lportaudio")
add_executable(findLib findLib.c)
