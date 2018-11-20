//
//  JSONContainerTests.cpp
//  remote_core_unit_tests
//
//  Created by David Moore on 11/3/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <iostream>
#include <gtest/gtest.h>
#include <limits>
#include "JSONContainer.hpp"

using namespace RemoteCore;

TEST(JSONContainerTests, EncodeDecodeInt) {
    JSONContainer container;
    
    const int value = std::numeric_limits<int>::max();
    container.setIntForKey(value, "EncodeDecodeInt");
    
    ASSERT_EQ(value, container.intForKey("EncodeDecodeInt"));
}

TEST(JSONContainerTests, EncodeDecodeUnsignedInt) {
    JSONContainer container;
    
    const unsigned int value = std::numeric_limits<unsigned int>::max();
    container.setUnsignedIntForKey(value, "EncodeDecodeUnsignedInt");
    
    ASSERT_EQ(container.unsignedIntForKey("EncodeDecodeUnsignedInt"), value);
}

TEST(JSONContainerTests, EncodeDecodeFloat) {
    JSONContainer container;
    
    const double value = std::numeric_limits<double>::max();
    container.setFloatForKey(value, "EncodeDecodeFloat");
    
    ASSERT_EQ(container.floatForKey("EncodeDecodeFloat"), value);
}

TEST(JSONContainerTests, EncodeDecodeBool) {
    JSONContainer container;
    
    const bool a = true;
    const bool b = false;
    container.setBoolForKey(a, "EncodeDecodeBool_A");
    container.setBoolForKey(b, "EncodeDecodeBool_B");
    
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
    
    auto str = randomString(0xFFF);
    container.setStringForKey(str, "EncodeDecodeString");
    
    ASSERT_EQ(str, container.stringForKey("EncodeDecodeString"));
}

TEST(JSONContainerTests, EncodeDecodeIntArray) {
    JSONContainer container;
    container.initializeForArray();
    
    auto vec = std::vector<int>{-2, -1, 0, 1, 2, 3, 4, 5, 127};
    container.emplaceArray(vec);
    
    ASSERT_EQ(vec, container.intArray());
}

TEST(JSONContainerTests, EncodeDecodeUnsignedIntArray) {
    JSONContainer container;
    container.initializeForArray();
    
    auto vec = std::vector<unsigned int>{0, 1, 2, 3, 4, 5, 254, 255};
    container.emplaceArray(vec);
    
    ASSERT_EQ(vec, container.unsignedIntArray());
}

TEST(JSONContainerTests, EncodeDecodeFloatArray) {
    JSONContainer container;
    container.initializeForArray();
    
    auto vec = std::vector<double>{-10e7, -10.5, 0.35, 9.8, 10.252525e3};
    container.emplaceArray(vec);
    
    auto vec2 = container.floatArray();
    ASSERT_EQ(vec.size(), vec2.size());
    
    for (int i = 0; i < vec2.size(); i++) {
        ASSERT_FLOAT_EQ(vec[i], vec2[i]);
    }
}

TEST(JSONContainerTests, EncodeDecodeBoolArray) {
    JSONContainer container;
    container.initializeForArray();
    
    auto vec = std::vector<bool>{true, true, true, false, true, false, false, true};
    container.emplaceArray(vec);
    
    ASSERT_EQ(vec, container.boolArray());
}

TEST(JSONContainerTests, EncodeDecodeStringArray) {
    JSONContainer container;
    container.initializeForArray();
    
    auto vec = std::vector<std::string>{"Foo", "Bar", "Hello", "World"};
    container.emplaceArray(vec);
    
    ASSERT_EQ(vec, container.stringArray());
}

TEST(JSONContainerTests, EncodeDecodeNestedContainers) {
    JSONContainer container;
    container.initializeForArray();
    
    int a = 123;
    std::string b = "Boo";
    std::vector<unsigned int> c{15, 23, 105, std::numeric_limits<unsigned int>::max()};
    
    const int len = 10;
    
    for (int i = 0; i < len; i++) {
        auto nestedContainer = container.requestNestedContainer();
        nestedContainer->setIntForKey(a, "a");
        nestedContainer->setStringForKey(b, "b");
        
        auto arrayContainer = nestedContainer->requestNestedContainer(true);
        arrayContainer->emplaceArray(c);
        
        nestedContainer->submitNestedContainerForKey(std::move(arrayContainer), "c");
        
        container.submitNestedContainer(std::move(nestedContainer));
    }
    
    auto nestedContainers = container.containerArray();
    ASSERT_EQ(nestedContainers.size(), len);
    
    for (auto &&nestedContainer : nestedContainers) {
        ASSERT_EQ(a, nestedContainer->intForKey("a"));
        ASSERT_EQ(b, nestedContainer->stringForKey("b"));
        
        auto arrayContainer = nestedContainer->containerForKey("c");
        ASSERT_EQ(c, arrayContainer->unsignedIntArray());
    }
}

TEST(JSONContainerTests, EncodeDecodeEmbeddedContainer) {
    JSONContainer container;
    auto embeddedContainer = container.requestNestedContainer();
    
    const int intValue = rand();
    embeddedContainer->setIntForKey(intValue, "A");
    
    const unsigned int uIntValue = std::numeric_limits<unsigned int>::max();
    embeddedContainer->setUnsignedIntForKey(uIntValue, "E");
    
    const double doubleValue = std::numeric_limits<double>::max();
    embeddedContainer->setFloatForKey(doubleValue, "F");
    
    const bool boolValue = rand() % 1;
    embeddedContainer->setBoolForKey(boolValue, "B");
    
    auto stringValue = randomString(0xFFF);
    embeddedContainer->setStringForKey(stringValue, "C");
    
    auto nestedContainer = embeddedContainer->requestNestedContainer();
    
    const int intValue2 = rand();
    nestedContainer->setIntForKey(intValue2, "A");
    
    const unsigned int uIntValue2 = std::numeric_limits<unsigned int>::max();
    nestedContainer->setUnsignedIntForKey(uIntValue2, "E");
    
    const double doubleValue2 = std::numeric_limits<double>::max();
    nestedContainer->setFloatForKey(doubleValue2, "F");
    
    const bool boolValue2 = rand() % 1;
    nestedContainer->setBoolForKey(boolValue2, "B");
    
    auto stringValue2 = randomString(0xFFF);
    nestedContainer->setStringForKey(stringValue2, "C");
    
    embeddedContainer->submitNestedContainerForKey(std::move(nestedContainer), "D");
    container.submitNestedContainerForKey(std::move(embeddedContainer), "D");
    
    auto decodedEmbeddedContainer = container.containerForKey("D");
    ASSERT_TRUE(decodedEmbeddedContainer != nullptr);
    ASSERT_EQ(decodedEmbeddedContainer->intForKey("A"), intValue);
    ASSERT_EQ(decodedEmbeddedContainer->unsignedIntForKey("E"), uIntValue);
    ASSERT_EQ(decodedEmbeddedContainer->floatForKey("F"), doubleValue);
    ASSERT_EQ(decodedEmbeddedContainer->boolForKey("B"), boolValue);
    ASSERT_EQ(decodedEmbeddedContainer->stringForKey("C"), stringValue);
    
    auto decodedNestedContainer = decodedEmbeddedContainer->containerForKey("D");
    ASSERT_TRUE(decodedNestedContainer != nullptr);
    ASSERT_EQ(decodedNestedContainer->intForKey("A"), intValue2);
    ASSERT_EQ(decodedNestedContainer->unsignedIntForKey("E"), uIntValue2);
    ASSERT_EQ(decodedNestedContainer->floatForKey("F"), doubleValue2);
    ASSERT_EQ(decodedNestedContainer->boolForKey("B"), boolValue2);
    ASSERT_EQ(decodedNestedContainer->stringForKey("C"), stringValue2);
}

TEST(JSONContainerTests, InitializeFromJSON) {
    std::string payload = R"({"A": "Hello","B": 2, "C": 3.5, "D": true})";
    JSONContainer container(payload);
    
    ASSERT_EQ(container.stringForKey("A"), "Hello");
    ASSERT_EQ(container.intForKey("B"), 2);
    ASSERT_FLOAT_EQ(container.floatForKey("C"), 3.5);
    ASSERT_EQ(container.boolForKey("D"), true);
}

TEST(JSONContainerTests, GenerateData) {
    JSONContainer container;
    container.setIntForKey(5, "A");
    container.setStringForKey("Foo", "B");
    container.setFloatForKey(2.3, "C");
    container.setBoolForKey(true, "D");
    
    auto data = container.generateData();
    ASSERT_STREQ(data.c_str(), R"({"A":5,"B":"Foo","C":2.3,"D":true})");
}
