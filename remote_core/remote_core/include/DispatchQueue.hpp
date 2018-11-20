//
//  DispatchQueue.hpp
//  remote_core
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#ifndef DispatchQueue_hpp
#define DispatchQueue_hpp

#include <functional>
#include <thread>
#include <queue>

namespace RemoteCore {
    /**
     Enables asynchronous execution by using a std::thread backed queue.
     */
    class DispatchQueue {
    public:
        /**
         Void function that can be executed by the receiver.
         */
        typedef std::function<void (void)> Block;
        
    private:
        std::string name;
        std::mutex queueMutex;
        std::queue<Block> blockQueue;
        std::vector<std::thread> threads;
        std::condition_variable threadCondition;
        std::atomic_bool shouldQuit;
        
        void threadHandler(void);
        
    public:
        DispatchQueue(std::string name, size_t threadCount = 1);
        ~DispatchQueue();
        
        /**
         Executes the provided block on the queue.
         */
        void execute(Block block);
    };
}

#endif /* DispatchQueue_hpp */
