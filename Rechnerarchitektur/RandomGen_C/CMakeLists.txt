cmake_minimum_required(VERSION 3.5)
project(RandomGen_C)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(SOURCE_FILES
    randomGen.c)

add_executable(RandomGen_C ${SOURCE_FILES})