#
# Be sure to run `pod lib lint iZSecretChat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SecretChat'
  s.version          = '1.0.0'
  s.summary          = 'SecretChat uses signal protocol and AES for secure message encryption and decryption'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.b
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Pod For SecretChat
                       DESC

  s.homepage         = 'https://github.com/senmdu/SecretChat'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Senthil Kumar R' => 'senmdu96@gmail.com' }
  s.source           = { :git => 'https://github.com/senmdu/SecretChat.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.source_files = 'Source/Classes/**'
  s.resource_bundles = {'SecretChat' => ['Source/Assets/*.xcdatamodeld']}
  s.ios.vendored_frameworks = 'Source/Resources/SignalProtocol.framework', 'Source/Resources/CryptoSwift.framework'
  # s.resource_bundles = {
  #   'iZSecretChat' => ['Source/Assets/*.png']
  # }

  # s.frameworks = 'UIKit', 'MapKit'
end
