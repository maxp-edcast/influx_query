require_relative './lib/version.rb'
Gem::Specification.new do |s|
  s.name        = "influx_query"
  s.version     = InfluxQuery::VERSION
  s.date        = "2018-03-26"
  s.summary     = "query DSL for Influx"
  s.description = ""
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["max pleaner"]
  s.email       = 'maxpleaner@gmail.com'
  s.required_ruby_version = '~> 2.3'
  s.homepage    = "http://github.com/maxp-edcast/influx_query"
  s.files       = Dir["lib/**/*.rb", "bin/*", "**/*.md", "LICENSE"]
  s.require_path = 'lib'
  s.required_rubygems_version = ">= 2.7.3"
  s.executables = Dir["bin/*"].map &File.method(:basename)
  s.license     = 'MIT'
end
