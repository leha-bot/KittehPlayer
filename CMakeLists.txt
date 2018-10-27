cmake_minimum_required(VERSION 3.1.0)

project(KittehPlayer)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror -fstrict-aliasing -Wno-deprecated-declarations -Wno-unused-variable")

option(DEVELOP "Enable runtime QML reloading for developing." OFF)


find_package(Qt5Core REQUIRED)
find_package(Qt5 REQUIRED Qml Quick Gui Widgets Core)

find_package(Qt5QuickCompiler)
qtquick_compiler_add_resources(qml_QRC src/qml/qml.qrc)

set(SOURCES
	src/main.cpp
    src/mpvobject.cpp
)

if(DEVELOP)
set(SOURCES ${SOURCES} runtimeqml/runtimeqml.cpp)
add_definitions(-DQRC_SOURCE_PATH="${PROJECT_SOURCE_DIR}/src/qml")
endif(DEVELOP)

add_executable(KittehPlayer ${SOURCES} ${qml_QRC})

# Use the Qml/Quick modules from Qt 5.
target_link_libraries(KittehPlayer mpv)

qt5_use_modules(KittehPlayer Qml Quick Core Gui Widgets)




