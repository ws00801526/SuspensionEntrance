#
# Be sure to run `pod lib lint WMReactNative.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SuspensionEntrance'
  s.version          = '0.1.6'
  s.summary          = '仿微信实现悬浮窗入口功能'
  s.homepage         = 'https://github.com/ws00801526/SuspensionEntrance'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Fraker.XM' => '3057600441@qq.com' }
  s.source           = { :git => 'https://github.com/ws00801526/SuspensionEntrance.git', :tag => s.version.to_s }
  s.swift_versions = '5.0'
  s.ios.deployment_target = '9.0'
  s.source_files = 'SuspensionEntrance/OC/**/*'
end
