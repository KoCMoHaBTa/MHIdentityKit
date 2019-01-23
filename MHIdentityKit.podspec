Pod::Spec.new do |s|

  s.name         = "MHIdentityKit"
  s.version      = "1.7.1"
  s.source       = { :git => "https://github.com/KoCMoHaBTa/MHIdentityKit.git", :tag => "#{s.version}" }
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author    = "Milen Halachev"
  s.summary      = "OAuth2 and OpenID connect iOS Protocol Oriented Swift client library."
  s.homepage     = "https://github.com/KoCMoHaBTa/MHIdentityKit"

  s.swift_version = "4.2"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"

  s.source_files  = "MHIdentityKit/**/*.swift", "MHIdentityKit/MHIdentityKit.h"
  s.public_header_files = "MHIdentityKit/MHIdentityKit.h"

  s.exclude_files = "MHIdentityKit/**/iOS/*.swift", "MHIdentityKit/**/macOS/*.swift", "MHIdentityKit/**/tvOS/*.swift", "MHIdentityKit/**/watchOS/*.swift"

  s.ios.source_files  = "MHIdentityKit/**/iOS/*.swift"
  s.osx.source_files  = "MHIdentityKit/**/macOS/*.swift"
  s.tvos.source_files  = "MHIdentityKit/**/tvOS/*.swift"
  s.watchos.source_files  = "MHIdentityKit/**/watchOS/*.swift"

end
