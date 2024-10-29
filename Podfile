# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'AppleParty' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AppleParty
  pod 'Alamofire', '~> 5.9.1'
  pod 'SnapKit', '~> 5.0'
  pod 'Sparkle', '~> 2.6.3'
  pod 'Kanna', '~> 5.2'
  pod 'SWXMLHash', '~> 5.0'
  pod 'CoreXLSX', '~> 0.14'
  pod 'ExpandingDatePicker', '~> 1.0'
  pod 'KeychainAccess', '~> 4.2'
  
  target 'ApplePartyTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'ApplePartyUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
