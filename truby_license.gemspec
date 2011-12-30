# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = 'truby_license'
  s.version     = '0.1.0'
  s.date        = '2011-12-22'
  s.summary     = "True License for Ruby"
  s.description = "Create and read True License files in ruby"
  s.authors     = ["Einar Magnús Boson"]
  s.email       = 'einar.boson@gmail.com'
  s.files       = Dir["lib/*.rb"]
  s.homepage    = 'http://github.com/einarmagnus/truby_license'
  s.license = 'MIT'
  s.test_files = Dir["test/test_*.rb"]
  s.required_ruby_version = '>= 1.8.7' # I don't know, it may work on older ones too

  s.add_runtime_dependency "nokogiri", "~> 1.5" # I don't know, it may work on older ones too
  s.add_runtime_dependency "builder", "~> 3.0" # I don't know, it may work on older ones too


end
