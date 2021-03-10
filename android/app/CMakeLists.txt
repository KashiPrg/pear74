cmake_minimum_required(VERSION 3.6.0)

include_directories(../../include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

set(PEAR74_DIR "../../ios/Classes")
set(SOURCES
    ${PEAR74_DIR}/native_opencv.cpp
)
add_library(native_opencv SHARED ${SOURCES})
target_link_libraries(native_opencv lib_opencv)