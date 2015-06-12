Pod::Spec.new do |s|
  s.name         = "TFFileManager"
  s.version      = "0.0.1"
  s.summary      = "时光流影文件上传平台iOS客户端SDK"
  s.homepage     = "https://github.com/TimeFaceCoder/TFFileManager"
  s.license      = "Copyright (C) 2015 TimeFace, Inc.  All rights reserved."
  s.author             = { "Melvin" => "yangmin@timeface.cn" }
  s.social_media_url   = "http://www.timeface.cn"
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/TimeFaceCoder/TFFileManager.git",:tag => "0.0.1"}
  s.source_files  = "FileManager/**/*.{h,m}"
  s.requires_arc = true
  s.dependency 'AFNetworking'
  s.dependency 'EGOCache'
end
