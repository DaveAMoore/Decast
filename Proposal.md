# Proposal

## Overview
A device that can communicate with and control IR devices. This provides the ability to automate and remotely control numerous home devices, including TVs, set top boxes, fans, and much more. Rather than having to purchase new devices that can be controlled remotely, this device will provide IoT capabilities to any device that uses IR as a control point.

## Software Components
There are three distinct components that will comprise the software for this project. Each individual unit will serve a particular function, and have varying degrees of complexity.

### On-Device API
Security is critical for this API and will be considered as an integral component during its design. Infrared (IR) codes will be transmitted using the device API. A goal regarding this system is to have minimal API surface area to reduce security risks and streamline maintenance.

### Server-side API
This server-side API will be the main control point for the device, which will act as a conduit for remote interaction. The *Mobile Application* should use this interface for interacting with the device, and thus controlling external devices. AWS Lambda, S3, DynamoDB, and API Gateway will be used to implement this API. The Lambda function will be written in either Node.js or Java.

### Mobile Application
End-user application that will provide the control mechanism for the device, as mediated by the server-side API. A framework will be designed and developed to interact with the network API, thus abstracting complex logic from the design of the app. Interactive remote training will be built-in to the application, as will the controlling of trained devices. The app will be written using Objective-C and Swift.

## Prototype Plan
Evolutionary and horizontal development will be used for the overall project prototyping. Vertical prototyping will be applied for particular subsystem development. Project integration is expected to be a horizontal process.

## Hardware
Either an Arduino Uno R3 or a Raspberry Pi will be used as the hardware device. IR sensors and transmitters will be used to learn and control external devices, respectively. Wi-Fi and Bluetooth are required to communicate/pair with the device. Radio frequency (RF) antennas may be added, if time permitting, to interact with devices that use RF for control purposes.

## Anticipated Challenges
Maintaining security throughout the entire system, and anticipating possible vulnerabilities will be difficult. The development of this project under the provided timeline will undoubtedly be a challenge as well. Finally, making sure the cumulative API is designed properly is important, and is anticipated to take some effort.
