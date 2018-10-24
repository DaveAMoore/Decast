#!/bin/sh
cd Hardware/aws-iot-device-sdk-cpp/
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Debug ../.
make aws-iot-sdk-cpp
