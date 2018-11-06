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
    container.setIntForKey(value, "EncodeDecodeInt");
    
    ASSERT_EQ(value, container.intForKey("EncodeDecodeInt"));
}

TEST(JSONContainerTests, EncodeDecodeUnsignedInt) {
    JSONContainer container;
    
    const unsigned int value = UINT_MAX;
    container.setUnsignedIntForKey(value, "EncodeDecodeUnsignedInt");
    
    ASSERT_EQ(container.unsignedIntForKey("EncodeDecodeUnsignedInt"), value);
}

TEST(JSONContainerTests, EncodeDecodeFloat) {
    JSONContainer container;
    
    const double value = MAXFLOAT;
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

TEST(JSONContainerTests, EncodeDecodeEmbeddedContainer) {
    JSONContainer container;
    auto embeddedContainer = container.requestNestedContainer();
    
    const int intValue = rand();
    embeddedContainer->setIntForKey(intValue, "A");
    
    const unsigned int uIntValue = UINT_MAX;
    embeddedContainer->setUnsignedIntForKey(uIntValue, "E");
    
    const double doubleValue = MAXFLOAT;
    embeddedContainer->setFloatForKey(doubleValue, "F");
    
    const bool boolValue = rand() % 1;
    embeddedContainer->setBoolForKey(boolValue, "B");
    
    auto stringValue = randomString(0xFFF);
    embeddedContainer->setStringForKey(stringValue, "C");
    
    auto nestedContainer = embeddedContainer->requestNestedContainer();
    
    const int intValue2 = rand();
    nestedContainer->setIntForKey(intValue2, "A");
    
    const unsigned int uIntValue2 = UINT_MAX;
    nestedContainer->setUnsignedIntForKey(uIntValue2, "E");
    
    const double doubleValue2 = MAXFLOAT;
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
    
    size_t dataLength = 0;
    auto data = container.generateData(dataLength);
    ASSERT_STREQ((char *)data.get(), R"({"A":5,"B":"Foo","C":2.3,"D":true})");
}
