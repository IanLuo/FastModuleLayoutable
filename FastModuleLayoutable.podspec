# coding: utf-8
Pod::Spec.new do |s|
 s.name         = "FastModuleLayoutable"
 s.version      = "0.0.1"
 s.summary      = "Provide layout ability to FastModule"
 s.description  = "Layout for FastModule"
 s.homepage     = "https://github.com/IanLuo/FastModuleLayoutable"
 s.license      = "MIT"
 s.author             = { "luoxu" => "ianluo63@gmail.com" }
 s.source       = { :git => "git@github.com:IanLuo/FastModuleLayoutable.git", :tag => "#{s.version}" }
 s.source_files  = "Sources/**/*.swift"
 s.ios.deployment_target  = '8.0'
 s.dependency 'FastModule'
 s.dependency 'YogaKit'
 s.dependency 'Aspects', '~> 1.4.1'
end
