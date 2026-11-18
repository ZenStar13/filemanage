include(FetchContent)

# --- Dear ImGui (no upstream CMake support, so we define the targets) -------
FetchContent_Declare(imgui
    GIT_REPOSITORY https://github.com/ocornut/imgui.git
    GIT_TAG        v1.93.0
    GIT_SHALLOW    TRUE)
FetchContent_MakeAvailable(imgui)

add_library(imgui STATIC
    ${imgui_SOURCE_DIR}/imgui.cpp
    ${imgui_SOURCE_DIR}/imgui_draw.cpp
    ${imgui_SOURCE_DIR}/imgui_tables.cpp
    ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    ${imgui_SOURCE_DIR}/misc/cpp/imgui_stdlib.cpp)
target_include_directories(imgui SYSTEM PUBLIC ${imgui_SOURCE_DIR})
target_compile_definitions(imgui PUBLIC IMGUI_DISABLE_OBSOLETE_FUNCTIONS)
add_library(imgui::imgui ALIAS imgui)

# --- GLFW: prefer the system package, fall back to building it --------------
find_package(glfw3 3.3 QUIET)
if(NOT glfw3_FOUND)
    FetchContent_Declare(glfw
        GIT_REPOSITORY https://github.com/glfw/glfw.git
        GIT_TAG        3.4
        GIT_SHALLOW    TRUE)
    set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(glfw)
endif()
find_package(OpenGL REQUIRED)

add_library(imgui_backend_glfw_opengl3 STATIC
    ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp)
target_include_directories(imgui_backend_glfw_opengl3 SYSTEM PUBLIC ${imgui_SOURCE_DIR}/backends)
target_link_libraries(imgui_backend_glfw_opengl3 PUBLIC imgui glfw OpenGL::GL)
add_library(imgui::backend_glfw_opengl3 ALIAS imgui_backend_glfw_opengl3)

# --- doctest for unit tests -------------------------------------------------
if(FM_BUILD_TESTS)
    FetchContent_Declare(doctest
        GIT_REPOSITORY https://github.com/doctest/doctest.git
        GIT_TAG        v2.4.12
        GIT_SHALLOW    TRUE)
    FetchContent_MakeAvailable(doctest)
endif()
