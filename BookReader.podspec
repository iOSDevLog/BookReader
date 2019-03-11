#
# Be sure to run `pod lib lint BookReader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BookReader'
  s.version          = '0.1.3'
  s.summary          = 'Sample code for PDFKit on iOS 11, clone of iBooks.app built on top of PDFKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  https://github.com/kishikawakatsumi/BookReader
  Usage
  Import Your Own PDFs
  The easiest way to import your PDFs is to email your PDF file to your iOS device. Navigate to the email and ensure that the attachment is there. Tap and hold the document attachment icon. This should open a popover on the iPad, or an action sheet on the iPhone, that shows all of the apps that open your document type. BookReader app should show up in the list. Tap BookReader app icon and BookReader app should launch and receive the document from the email.
                       DESC

  s.homepage         = 'https://github.com/Allogy/BookReader'
  s.screenshots      = 'https://raw.githubusercontent.com/Allogy/BookReader/master/Screenshot/0.png', 'https://raw.githubusercontent.com/Allogy/BookReader/master/Screenshot/1.png', 'https://raw.githubusercontent.com/Allogy/BookReader/master/Screenshot/2.png', 'https://raw.githubusercontent.com/Allogy/BookReader/master/Screenshot/3.png',
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iosdevlog' => 'iosdevlog@iosdevlog.com' }
  s.source           = { :git => 'https://github.com/Allogy/BookReader.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/allogy'

  s.ios.deployment_target = '11.0'

  s.source_files = 'BookReader/Classes/**/*'
  
  s.resource_bundles = {
      'BookReader' => ['BookReader/Assets/*.png', 'BookReader/Assets/*.xib', 'BookReader/Assets/*.storyboard', 'BookReader/Assets/*.xcassets']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'PDFKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = '4.2'
end
