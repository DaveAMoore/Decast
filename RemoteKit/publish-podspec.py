from subprocess import Popen, PIPE
import subprocess
import os
from datetime import datetime
import time
import sys

podspecs = ["RFCore.podspec"]

print (str(datetime.now()) + ": Publishing podspecs...")
for podspec in podspecs:
    print(str(datetime.now()) + ": Publishing " + podspec + "...")

    process = Popen(["pod", "repo","push","Internal-Specs",podspec,"--sources=https://github.com/DaveAMoore/Internal-Specs.git","--allow-warnings"], stdout=PIPE)
    (output, error) = process.communicate()
    exit_code = process.wait()
    if exit_code != 0:
        if "Unable to accept duplicate entry for:" in str(output):
            print (podspec + " is already published.")
        else:
            print(output)
            print(error)
            print("Failed to publish " + podspec)
            quit(exit_code)
    else:
        print(str(datetime.now()) + ": Published " + podspec)
