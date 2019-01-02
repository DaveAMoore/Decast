Pod::Spec.new do |s|
    s.name         = "RemoteKit"
    s.version      = "0.9.1"
    s.summary      = "Used for communicating with remote_core."
    s.homepage     = "https://github.com/DaveAMoore/Decast"
    s.license      = { :type => "MIT", :file => "LICENSE.txt" }
    s.author       = { "David Moore" => "mooredev@me.com" }
    s.source       = { :git => "https://github.com/DaveAMoore/Decast.git", :tag => "v0.9.1" }
    
    s.requires_arc = true
    s.swift_version = "4.2"
    s.module_map = "RemoteKit/core-module.modulemap"
    s.pod_target_xcconfig = {
        "DEFINES_MODULE" => "YES",
        "APPLICATION_EXTENSION_API_ONLY" => "YES",
        "SWIFT_INCLUDE_PATHS" => "$(SRCROOT)/RemoteKit"
    }
    s.frameworks   = "Foundation"
    s.ios.deployment_target = "12.0"
    
    s.dependency "AWSAutoScaling",              "~> 2.6.33"
    s.dependency "AWSCore",                     "~> 2.6.33"
    s.dependency "AWSCognito",                  "~> 2.6.33"
    s.dependency "AWSCognitoIdentityProvider",  "~> 2.6.33"
    s.dependency "RFCore",                      "~> 2.2"
    s.dependency "SFKit",                       "~> 1.7"
    
    s.preserve_paths = "RemoteKit/*.modulemap"
    s.source_files = "RemoteKit/*.{h,m,swift}", "RemoteKit/**/*.{h,m,swift}"
    s.public_header_files = "RemoteKit/RemoteKit.h"
end


