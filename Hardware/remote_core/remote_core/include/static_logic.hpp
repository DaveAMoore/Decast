//
//  static_logic.h
//  remote_core
//
//  Created by David Moore on 11/11/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef static_logic_hpp
#define static_logic_hpp

namespace logic {
    template <typename T, typename F>
    auto static_if(std::true_type, T t, F f) { return t; }
    
    template <typename T, typename F>
    auto static_if(std::false_type, T t, F f) { return f; }
    
    template <bool B, typename T, typename F>
    auto static_if(T t, F f) { return static_if(std::integral_constant<bool, B>{}, t, f); }
    
    template <bool B, typename T>
    auto static_if(T t) { return static_if(std::integral_constant<bool, B>{}, t, [](auto&&...){}); }
}


#endif /* static_logic_hpp */
