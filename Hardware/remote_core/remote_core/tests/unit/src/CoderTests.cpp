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

using namespace RemoteCore;

class Mock : public Coding {
public:
    
    
    void encodeWithCoder(Coder *aCoder) override {
        
    }
    
    void decodeWithCoder(Coder *aCoder) override {
        
    }
};
