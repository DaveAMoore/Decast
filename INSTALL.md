# Installation

## Dependencies
You will need the following to build and run `remote_core`:
- OpenSSL (1.0.2 or later)
- CURL

To load additional dependencies (i.e., `aws-iot-device-sdk-cpp`) execute the following command:
``
./Scripts/configure.sh
``

This will initialize and load git submodules, which prepares the project for building. This should be followed by:
``
./Scripts/build-dependencies.sh
``

To build with debug symbols use the ``--debug`` option.

The above command will create a folder called _build_ in _Hardware/aws-iot-device-sdk-cpp/_ and then build the library for the current architecture.

## Building `remote_core`
Currently in the works.
