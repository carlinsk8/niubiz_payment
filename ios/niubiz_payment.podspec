#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint niubiz_payment.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'niubiz_payment'
  s.version          = '1.0.0'
  s.summary          = 'Niubiz Payment Flutter Plugin.'
  s.description      = <<-DESC
Niubiz Payment Flutter Plugin.
                       DESC
  s.homepage         = 'http://creegplay.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'creegplay' => 'carlin.08.12@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.vendored_frameworks = ['VisaNetSDK.framework', 'CardinalMobile.framework', 'TMXProfiling.framework', 'TMXProfilingConnections.framework']
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'niubiz_payment_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
