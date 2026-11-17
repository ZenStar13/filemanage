# Files — C++23 + Dear ImGui 1.93

Immediate-mode C++ GUI using the GLFW + OpenGL 3 backends. Built with CMake
(presets + Ninja). Dear ImGui, GLFW and doctest are fetched with `FetchContent`;
a system GLFW is used when available.

```bash
cd apps/cpp-imgui
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
./build/debug/fm_imgui

cmake --preset release && cmake --build --preset release   # optimised build
```

Prerequisites: a C++23 compiler (GCC 13+ / Clang 17+), CMake ≥ 3.25, Ninja,
`libgl-dev` (plus `libglfw3-dev`, optional).

## Layout

```
src/
├── domain/            DirectoryPath, FileEntry, DirectoryListing, NavigationHistory, Place, FsError, Ports
├── application/       BrowseDirectory, ListPlaces          (std::expected-based)
├── infrastructure/    LocalFileSystem (std::filesystem), XdgPlaces
├── presentation/
│   ├── theme/         Palette.hpp (tokens), Theme (ImGuiStyle + fonts), Glyphs
│   ├── viewmodel/     BrowserViewModel, Action (std::variant), DirectoryLoader (worker thread)
│   ├── view/          BrowserView + Toolbar/Sidebar/FileTable/StatusBar
│   └── Format         human-readable sizes, dates, kinds
├── platform/          GlfwWindow — RAII host for GLFW, the GL context and ImGui backends
├── app/               Application — frame loop
└── main.cpp           composition root
tests/                 doctest unit tests (domain, use case, filesystem adapter)
```

Each folder is its own CMake target, so the build enforces the layer rules. The
debug preset compiles our code with `-Wall -Wextra -Wpedantic -Wconversion
-Wshadow … -Werror`. `.clang-format` and `.clang-tidy` are included.

## Notes

* **Immediate-mode MVVM:** views receive `const BrowserViewModel&` and append
  `Action`s, and `dispatch()` applies them after the frame.
* `ImGuiListClipper` submits only visible rows, so `/usr/lib` stays cheap.
* The loop sleeps in `glfwWaitEventsTimeout` while idle. After any event it
  renders a short burst at 60 FPS, because ImGui spreads queued input over
  several frames ("input trickling"), and it polls while a load is running.
* ImGui ≥ 1.92 rasterises glyphs on demand, so the Nerd Font icons need no glyph
  ranges. ImGui sizes fonts by line height, so em-based tokens are converted
  (`dimens::fontSize`).
* Assets (fonts) are copied next to the binary at build time and resolved
  through `/proc/self/exe`.
