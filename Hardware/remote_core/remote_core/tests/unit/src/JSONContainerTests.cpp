//
//  JSONContainerTests.cpp
//  remote_core_unit_tests
//
//  Created by David Moore on 11/3/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <iostream>
#include <gtest/gtest.h>
#include "JSONContainer.hpp"

using namespace RemoteCore;

TEST(JSONContainerTests, EncodeDecodeInt) {
    JSONContainer container;

    const int value = INT_MAX;
    container.encodeIntForKey(value, "EncodeDecodeInt");
    
    ASSERT_EQ(value, container.intForKey("EncodeDecodeInt"));
}

TEST(JSONContainerTests, EncodeDecodeBool) {
    JSONContainer container;
    
    const bool a = true;
    const bool b = false;
    container.encodeBoolForKey(a, "EncodeDecodeBool_A");
    container.encodeBoolForKey(b, "EncodeDecodeBool_B");
    
    ASSERT_EQ(a, container.boolForKey("EncodeDecodeBool_A"));
    ASSERT_EQ(b, container.boolForKey("EncodeDecodeBool_B"));
}

std::string randomString(size_t length) {
    auto randchar = []() -> char {
        const char charset[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz";
        const size_t max_index = (sizeof(charset) - 1);
        return charset[rand() % max_index];
    };
    
    std::string str(length, 0);
    std::generate_n(str.begin(), length, randchar);
    
    return str;
}

TEST(JSONContainerTests, EncodeDecodeString) {
    JSONContainer container;
    
    auto str = randomString(0xFFFFF);
    container.encodeStringForKey(str, "EncodeDecodeString");
    
    ASSERT_EQ(str, container.stringForKey("EncodeDecodeString"));
}

TEST(JSONContainerTests, Encod) {
    
}
