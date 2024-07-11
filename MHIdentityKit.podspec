Pod::Spec.new do |s|

  s.name         = "MHIdentityKit"
  s.version      = "1.14.0"
  s.source       = { :git => "https://github.com/KoCMoHaBTa/#{s.name}.git", :tag => "#{s.version}" }
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = "Milen Halachev"
  s.summary      = "OAuth2 and OpenID connect iOS Protocol Oriented Swift client library."
  s.homepage     = "https://github.com/KoCMoHaBTa/#{s.name}"

  s.swift_version = "5.10"
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "4.0"
  s.tvos.deployment_target = "12.0"

  s.source_files  = "#{s.name}/**/*.swift", "#{s.name}/**/*.{h,m}"
  s.public_header_files = "#{s.name}/**/*.h"

  s.ios.exclude_files = "#{s.name}/**/macOS/*.swift", "#{s.name}/**/tvOS/*.swift", "#{s.name}/**/watchOS/*.swift"
  s.osx.exclude_files = "#{s.name}/**/iOS/*.swift", "#{s.name}/**/tvOS/*.swift", "#{s.name}/**/watchOS/*.swift"
  s.tvos.exclude_files = "#{s.name}/**/iOS/*.swift", "#{s.name}/**/macOS/*.swift", "#{s.name}/**/watchOS/*.swift"
  s.watchos.exclude_files = "#{s.name}/**/iOS/*.swift", "#{s.name}/**/macOS/*.swift", "#{s.name}/**/tvOS/*.swift"

end
