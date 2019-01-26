Pod::Spec.new do |s|

  s.name         = "MHIdentityKit"
  s.version      = "1.7.2"
  s.source       = { :git => "https://github.com/KoCMoHaBTa/#{s.name}.git", :tag => "#{s.version}" }
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = "Milen Halachev"
  s.summary      = "OAuth2 and OpenID connect iOS Protocol Oriented Swift client library."
  s.homepage     = "https://github.com/KoCMoHaBTa/#{s.name}"

  s.swift_version = "4.2"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "3.0"
  s.tvos.deployment_target = "10.0"

  s.source_files  = "#{s.name}/**/*.swift", "#{s.name}/**/*.{h,m}"
  s.public_header_files = "#{s.name}/**/*.h"

  s.exclude_files = "#{s.name}/**/iOS/*.swift", "#{s.name}/**/macOS/*.swift", "#{s.name}/**/tvOS/*.swift", "#{s.name}/**/watchOS/*.swift"

  s.ios.source_files  = "#{s.name}/**/iOS/*.swift"
  s.osx.source_files  = "#{s.name}/**/macOS/*.swift"
  s.tvos.source_files  = "#{s.name}/**/tvOS/*.swift"
  s.watchos.source_files  = "#{s.name}/**/watchOS/*.swift"

end
