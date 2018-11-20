//
//  DispatchQueue.cpp
//  remote_core
//
//  Created by David Moore on 11/20/18.
//  Copyright © 2018 David Moore. All rights reserved.
//

#include "DispatchQueue.hpp"

using namespace RemoteCore;

DispatchQueue::DispatchQueue(std::string name, size_t threadCount) : name(name), threads(threadCount) {
    // Initialize the threads.
    for (size_t i = 0; i < threads.size(); i++) {
        threads[i] = std::thread(std::bind(&DispatchQueue::threadHandler, this));
    }
}

DispatchQueue::~DispatchQueue() {
    // Signal the dispatch threads to finish.
    shouldQuit = true;
    threadCondition.notify_all();
    
    // Join threads to allow for work to be completed.
    for (size_t i = 0; i < threads.size(); i++) {
        auto &thread = threads[i];
        if (thread.joinable()) {
            thread.join();
        }
    }
}

void DispatchQueue::threadHandler() {
    // Aquire the lock.
    std::unique_lock<std::mutex> lock(queueMutex);
    
    do {
        // Wait until we have the data.
        threadCondition.wait(lock, [this]() {
            return blockQueue.size() || shouldQuit;
        });
        
        // After waiting, we now own the lock.
        if (blockQueue.size()) {
            auto block = std::move(blockQueue.front());
            blockQueue.pop();
            
            // Unlock, since we're finished with the block queue.
            lock.unlock();
            
            // Execute the block.
            block();
            
            // Aquire a lock again.
            lock.lock();
        }
    } while (!shouldQuit);
}

void DispatchQueue::execute(Block block) {
    std::unique_lock<std::mutex> lock(queueMutex);
    blockQueue.push(block);
    
    // Unlock before notifying the threads.
    lock.unlock();
    threadCondition.notify_all();
}
