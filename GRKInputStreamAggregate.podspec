Pod::Spec.new do |s|
  s.name         = "GRKInputStreamAggregate"
  s.version      = "1.0"
  s.summary      = "A stream aggregator that reads from a concatenated sequence of other inputs."
  s.description  = <<-DESC
		A stream aggregator that reads from a concatenated sequence of other inputs. Use this to combine multiple input streams (and data blobs) together into one. This is useful when uploading multipart MIME bodies.
    DESC
  s.homepage     = "https://github.com/levigroker/GRKInputStreamAggregate"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Levi Brown" => "levigroker@gmail.com" }
  s.social_media_url = 'https://twitter.com/levigroker'
  s.source       = { :git => "https://github.com/levigroker/GRKInputStreamAggregate.git", :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.source_files = 'GRKInputStreamAggregate/**/*.{h,m}'
  s.frameworks = 'Foundation'
end
