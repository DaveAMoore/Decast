# Proposal

## Overview
Fill in later tonight…

## Software Components
There are three distinct components that will comprise the software for this project. Each individual unit will serve a particular function, and have varying degrees of complexity.

### On-Device API
The hardware module designed and developed by the the team will have an API that enables interaction between it and the *Cloud API*. There are multiple components of this subsystem that should be illustrated. Security is critical for this system, and it will begin with a secure authentication establishment process between the device and the server-side API. Besides security, the device API will allow for specific infrared (IR) codes to be transmitted, which will be communicated by the server. The intention of this interface is to provide ample functionality, while maintaining a minimal surface of attack.

### Cloud API
A server-side cloud API will serve as the main control point for the device, thus acting as a conduit for remote interaction. Amazon Web Services will be used to host the service at a low-cost, while also maintaining maximum availability at all times. Load balancing will be applied sparingly for the prototyping stage, as it will not be necessary. Ideally, AWS Lambda will be used as an on-demand provisional compute service to reduce costs further. It is likely that the server-side API will be written using JavaScript (i.e., NodeJS). In addition to compute services, it is reasonable that a database service like DynamoDB and a storage service (i.e., S3) will be used to support additional functionality.

### Mobile Application
An end-user application will be developed to provide a control mechanism for the device, as mediated by the cloud API. A framework will be developed to interact with the server-side API, which will allow for the abstraction of complex logic within the application itself. Furthermore, using a framework-based approach will allow for modularity with respect to developing applications for multiple platforms. Currently, the application will be targeted for iOS and watchOS, but there may be the possibility of an Android application as well, if time permits such. The application will allow a user to control devices such as a TV, AV receiver, set top box, etc. Any devices that can be controlled with infrared will be applicable for manipulation through the application. Learning IR codes for a particular device will be built-in to the functionality of the application.

## Prototype Plan
Throughout the course of creating the device, there may be multiple prototyping methods used; however, the most dominant prototyping will be evolutionary and horizontal with the development of the various components to a broad level to ensure the system integrates together into a functioning device. *Add additional details (Exp + Vert for certain comps?)*

## Hardware
The hardware that will be required to be implemented include the Arduino Uno R3 board as well as various sensors and transmitters to be used in order to communicate with devices. The sensors and transmitters required include IR (infrared) in order to communicate and manipulate devices of interest, as well as bluetooth and/or wifi transmitters in order to communicate with the user. In addition, the inclusion of RF technology would also extend the versatility of the device into being able to communicate with a wider range of devices that are becoming more prevalent.

## Anticipated Challenges
An anticipated challenge that will be one of the major point of focus throughout the project is the implementation and maintanance of security. In order to be able to store multiple IR frequencies and radio frequencies and communicate with a user through an external interface from the Arduino board, security will be integral in preventing any avenues of attacks for the device. *Add additional details*