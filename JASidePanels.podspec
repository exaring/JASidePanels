Pod::Spec.new do |s|
  s.name         = 'JASidePanels'
  s.version      = '1.0.1-exaring'
  s.platform     = :ios, '5.0'
  s.summary      = 'Reveal side ViewControllers similar to Facebook/Path\'s menu. Forked from https://github.com/cdzombak/JASidePanels.git.'
  s.homepage     = 'https://github.com/gotosleep/JASidePanels'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Jesse Andersen' => 'https://github.com/gotosleep' }

  s.source       = { :git => 'https://github.com/exaring/JASidePanels.git', :tag => '1.0.1-exaring' }

  s.source_files = 'JASidePanels/Source/*.{h,m}'
  s.public_header_files = 'JASidePanels/Source/*.h'

  s.framework    = 'UIKit'
  s.requires_arc = true
end
