cmake_minimum_required(VERSION 3.25)

project(fm_imgui
    VERSION 0.1.0
    DESCRIPTION "File manager first draft - Dear ImGui front-end"
    LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(FM_BUILD_TESTS "Build unit tests" ON)
option(FM_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)

include(cmake/CompilerWarnings.cmake)
include(cmake/Dependencies.cmake)

# ---------------------------------------------------------------------------
# Layers are separate targets so the dependency rule is enforced by the build:
#   domain <- application <- infrastructure
#                         <- presentation <- app (composition root)
# The domain and application layers know nothing about ImGui, GLFW or the OS.
# ---------------------------------------------------------------------------

add_library(fm_domain STATIC
    src/domain/DirectoryPath.cpp
    src/domain/DirectoryListing.cpp
    src/domain/FileEntry.cpp
    src/domain/NavigationHistory.cpp)
target_include_directories(fm_domain PUBLIC src)
fm_set_warnings(fm_domain)

add_library(fm_application STATIC
    src/application/BrowseDirectory.cpp
    src/application/ListPlaces.cpp)
target_link_libraries(fm_application PUBLIC fm_domain)
fm_set_warnings(fm_application)

add_library(fm_infrastructure STATIC
    src/infrastructure/LocalFileSystem.cpp
    src/infrastructure/XdgPlaces.cpp)
target_link_libraries(fm_infrastructure PUBLIC fm_domain)
fm_set_warnings(fm_infrastructure)

add_library(fm_presentation STATIC
    src/presentation/theme/Theme.cpp
    src/presentation/theme/Glyphs.cpp
    src/presentation/theme/Elevation.cpp
    src/presentation/Format.cpp
    src/presentation/viewmodel/DirectoryLoader.cpp
    src/presentation/viewmodel/BrowserViewModel.cpp
    src/presentation/view/BrowserView.cpp
    src/presentation/view/Toolbar.cpp
    src/presentation/view/Sidebar.cpp
    src/presentation/view/FileTable.cpp
    src/presentation/view/StatusBar.cpp)
target_link_libraries(fm_presentation PUBLIC fm_application imgui::imgui)
fm_set_warnings(fm_presentation)

add_executable(fm_imgui
    src/platform/GlfwWindow.cpp
    src/app/Application.cpp
    src/main.cpp)
target_link_libraries(fm_imgui PRIVATE fm_presentation fm_infrastructure imgui::backend_glfw_opengl3)
fm_set_warnings(fm_imgui)

# Ship the shared font next to the binary.
set(FM_FONT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../assets/fonts)
add_custom_command(TARGET fm_imgui POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory $<TARGET_FILE_DIR:fm_imgui>/assets/fonts
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${FM_FONT_DIR}/0xProtoNerdFont-Regular.ttf ${FM_FONT_DIR}/0xProtoNerdFont-Bold.ttf
            $<TARGET_FILE_DIR:fm_imgui>/assets/fonts/
    VERBATIM)

if(FM_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
