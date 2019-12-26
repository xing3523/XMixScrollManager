#
#  Be sure to run `pod spec lint XMixScrollManager.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|


  spec.name         = "XMixScrollManager"
  spec.version      = "0.0.1"
  spec.summary      = "A manager class for scroll together."
  spec.homepage     = "https://github.com/xing3523/XMixScrollManager.git"
  spec.license      = { :type => "MIT" }
  spec.authors      = { "xing" => "xinxof@foxmail.com" }
  spec.platform     = :ios, "8.0"
  spec.ios.deployment_target = "8.0"
  spec.source       = { :git => "https://github.com/xing3523/XMixScrollManager.git", :tag => "#{spec.version}" }
  
  spec.source_files  = "XMixScrollManager", "XMixScrollManager/*.{h,m}"
  spec.public_header_files = "XMixScrollManager/*.h"
  spec.requires_arc = true

end
