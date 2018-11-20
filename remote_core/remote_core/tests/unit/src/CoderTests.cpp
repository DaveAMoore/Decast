//
//  CoderTests.cpp
//  remote_core_unit_tests
//
//  Created by David Moore on 11/1/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include <iostream>
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "Coding.hpp"
#include "JSONContainer.hpp"

using namespace RemoteCore;

class Foo : public Coding {
public:
    int a;
    std::string b;
    
    Foo(int a = 10, std::string b = "Foo") : a(a), b(b) {}
    
    void encodeWithCoder(Coder *aCoder) const override {
        aCoder->encodeIntForKey(a, "a");
        aCoder->encodeStringForKey(b, "b");
    }
    
    void decodeWithCoder(const Coder *aCoder) override {
        a = aCoder->decodeIntForKey("a");
        b = aCoder->decodeStringForKey("b");
    }
};

class Mock : public Coding {
public:
    int a;
    std::string b;
    bool c;
    double d;
    unsigned int e;
    std::unique_ptr<Mock> f;
    std::vector<int> g;
    std::vector<Foo> h;
    
    Mock() {}
    
    Mock(bool shouldCreateF) : a(25), b("Hello world!"), c(true), d(7.25), e(254), g({1, 2, 3, 4, 5}), h({Foo(), Foo()}) {
        if (shouldCreateF) {
            f = std::make_unique<Mock>(false);
        }
    }
    
    void encodeWithCoder(Coder *aCoder) const override {
        aCoder->encodeIntForKey(a, "a");
        aCoder->encodeStringForKey(b, "b");
        aCoder->encodeBoolForKey(c, "c");
        aCoder->encodeFloatForKey(d, "d");
        aCoder->encodeUnsignedIntForKey(e, "e");
        aCoder->encodeObjectForKey(f.get(), "f");
        aCoder->encodeArrayForKey(g, "g");
        aCoder->encodeArrayForKey(h, "h");
    }
    
    void decodeWithCoder(const Coder *aCoder) override {
        a = aCoder->decodeIntForKey("a");
        b = aCoder->decodeStringForKey("b");
        c = aCoder->decodeBoolForKey("c");
        d = aCoder->decodeFloatForKey("d");
        e = aCoder->decodeUnsignedIntForKey("e");
        f = aCoder->decodeObjectForKey<Mock>("f");
        g = aCoder->decodeArrayForKey<int>("g");
        h = aCoder->decodeArrayForKey<Foo>("h");
    }
};

TEST(CoderTests, Encode) {
    Mock mock(true);
    auto container = std::make_unique<JSONContainer>();
    auto aCoder = std::make_unique<Coder>(std::move(container));
    
    aCoder->encodeRootObject(&mock);
    auto codedContainer = aCoder->invalidateCoder();
    
    auto data = codedContainer->generateData();
    ASSERT_STREQ(data.c_str(), R"({"a":25,"b":"Hello world!","c":true,"d":7.25,"e":254,"f":{"a":25,"b":"Hello world!","c":true,"d":7.25,"e":254,"g":[1,2,3,4,5],"h":[{"a":10,"b":"Foo"},{"a":10,"b":"Foo"}]},"g":[1,2,3,4,5],"h":[{"a":10,"b":"Foo"},{"a":10,"b":"Foo"}]})");
}

TEST(CoderTests, Decode) {
    std::string payload = R"({"a":25,"b":"Hello world!","c":true,"d":7.25,"e":254,"f":{"a":25,"b":"Hello world!","c":true,"d":7.25,"e":254}})";
    auto container = std::make_unique<JSONContainer>(payload);
    
    auto aCoder = std::make_unique<Coder>(std::move(container));
    auto mock = aCoder->decodeRootObject<Mock>();
    
    ASSERT_FALSE(mock == nullptr);
    ASSERT_EQ(mock->a, 25);
    ASSERT_STREQ(mock->b.data(), "Hello world!");
    ASSERT_TRUE(mock->c);
    ASSERT_FLOAT_EQ(mock->d, 7.25);
    ASSERT_EQ(mock->e, (unsigned int)254);
    ASSERT_EQ(mock->f->a, 25);
    ASSERT_STREQ(mock->f->b.data(), "Hello world!");
    ASSERT_EQ(mock->f->c, true);
    ASSERT_FLOAT_EQ(mock->f->d, 7.25);
    ASSERT_EQ(mock->f->e, (unsigned int)254);
    ASSERT_EQ(mock->f->f, nullptr);
}

TEST(CoderTests, EncodeDecode) {
    Mock mock(true);
    auto container = std::make_unique<JSONContainer>();
    auto aCoder = std::make_unique<Coder>(std::move(container));
    
    aCoder->encodeRootObject(&mock);
    auto codedContainer = aCoder->invalidateCoder();
    
    auto data = codedContainer->generateData();
    auto anotherContainer = std::make_unique<JSONContainer>(data);
    auto anotherCoder = std::make_unique<Coder>(std::move(anotherContainer));
    
    auto anotherMock = anotherCoder->decodeRootObject<Mock>();
    
    ASSERT_FALSE(anotherMock == nullptr);
    ASSERT_EQ(mock.a, anotherMock->a);
    ASSERT_STREQ(mock.b.data(), anotherMock->b.data());
    ASSERT_EQ(mock.c, anotherMock->c);
    ASSERT_FLOAT_EQ(mock.d, anotherMock->d);
    ASSERT_EQ(mock.e, anotherMock->e);
    ASSERT_EQ(mock.f->a, anotherMock->f->a);
    ASSERT_STREQ(mock.f->b.data(), anotherMock->f->b.data());
    ASSERT_EQ(mock.f->c, anotherMock->f->c);
    ASSERT_FLOAT_EQ(mock.f->d, anotherMock->f->d);
    ASSERT_EQ(mock.f->e, anotherMock->f->e);
    ASSERT_EQ(mock.f->f, anotherMock->f->f);
    ASSERT_EQ(mock.g, anotherMock->g);
    //ASSERT_EQ(mock.h, anotherMock->h);
}
