#
# Be sure to run `pod lib lint YREyeDistance.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YREyeDistance'
  s.version          = '0.1.0'
  s.summary          = 'A short description of YREyeDistance.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/yiren/YREyeDistance'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yiren' => 'ren_yi92@sina.com' }
  s.source           = { :git => 'https://github.com/yiren/YREyeDistance.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.static_framework = true
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |core|
      core.source_files = 'YREyeDistance/Classes/**/*'
      core.frameworks = 'UIKit', 'AVKit', 'Vision'
    end
  
  s.subspec 'ARKit' do |arkit|
      arkit.source_files = 'YREyeDistance/Classes/ARKit/**/*'
    end
  
  
end
