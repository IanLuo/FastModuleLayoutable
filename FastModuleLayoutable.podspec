# coding: utf-8
Pod::Spec.new do |s|
 s.name         = "FastModuleLayoutable"
 s.version      = "0.0.1"
 s.summary      = "添加模块布局功能"
 s.description  = "使用 Yogakit 来进行布局"
 s.homepage     = "http://gitlab.dev.hnair.net/ios-frameworks/HNAModuleLayoutable"
 s.license      = "MIT"
 s.author             = { "luoxu" => "ianluo63@gmail.com" }
 s.source       = { :git => "git@gitlab.dev.hnair.net:ios-frameworks/HNAModuleLayo\
table.git", :tag => "#{s.version}" }
 s.source_files  = "Sources/**/*.swift"
 s.ios.deployment_target  = '8.0'
 s.dependency 'FastModule'
 s.dependency 'YogaKit'
 s.dependency 'Aspects', '~> 1.4.1'
end
