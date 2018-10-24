#!/bin/sh

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
-d|--debug)
DEBUG=1
shift # past argument
shift # past value
;;
-s|--searchpath)
SEARCHPATH="$2"
shift # past argument
shift # past value
;;
-l|--lib)
LIBPATH="$2"
shift # past argument
shift # past value
;;
--default)
DEFAULT=YES
shift # past argument
;;
*)    # unknown option
POSITIONAL+=("$1") # save it in an array for later
shift # past argument
;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# handle non-option arguments
if [[ $# -ne 1 ]]; then
DEBUG=0
fi

cd ../Hardware/aws-iot-device-sdk-cpp/
mkdir build
cd build

if [$DEBUG == 1]
then
    cmake -DCMAKE_BUILD_TYPE=Debug ../.
else
    cmake ../.
fi

make aws-iot-sdk-cpp
