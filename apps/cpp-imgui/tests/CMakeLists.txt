add_executable(fm_tests
    main.cpp
    DomainTests.cpp
    ApplicationTests.cpp)
target_link_libraries(fm_tests PRIVATE fm_application fm_infrastructure doctest::doctest)
fm_set_warnings(fm_tests)
add_test(NAME fm_tests COMMAND fm_tests)
