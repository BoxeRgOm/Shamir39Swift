Pod::Spec.new do |s|
  s.name             = 'Shamir39Swift'
  s.version          = '0.1.0'
  s.summary          = 'This is a tool for Shamir39 on iOS.'
  s.swift_version    = '4.0'
  s.description      = 'This is a tool for Shamir39 on iOS. This ported Swift from Javascript Shamir39(https://github.com/iancoleman/shamir39).'

  s.homepage         = 'https://github.com/boxergom/Shamir39Swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'boxergom' => 'ms.kang@bono.tech' }
  s.source           = { :git => 'https://github.com/boxergom/Shamir39Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Shamir39Swift/Classes/**/*'
  s.dependency 'BigInt', '~> 5.0'
   
end
