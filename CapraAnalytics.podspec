Pod::Spec.new do |s|
  s.name             = 'CapraAnalytics'
  s.version          = '3.0.0'
  s.summary          = 'Native iOS SDK for Capra Analytics platform'
  s.description      = <<-DESC
Native iOS SDK for Capra Analytics platform. Track screen views, video engagement,
push notifications, scroll depth, conversions, and custom events with automatic
session management and offline support.
                       DESC

  s.homepage         = 'https://github.com/capra-solutions/analytics-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Capra Solutions' => 'info@capra.solutions' }
  s.source           = { :git => 'https://github.com/capra-solutions/analytics-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
  s.macos.deployment_target = '10.15'

  s.swift_version = '5.7'

  s.source_files = 'Sources/CapraAnalytics/**/*.swift'

  s.frameworks = 'Foundation'
end
