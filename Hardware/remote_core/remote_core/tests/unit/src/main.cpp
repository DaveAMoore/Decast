//
//  main.cpp
//  remote_core_unit_tests
//
//  Created by David Moore on 10/30/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <gtest/gtest.h>

int main(int argc, char **argv) {
    // The following line must be executed to initialize Google Mock
    // (and Google Test) before running the tests.
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
