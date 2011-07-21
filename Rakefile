# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "capistrano-windows-server"
  gem.homepage = "http://github.com/nilbus/capistrano-windows-server"
  gem.license = "MIT"
  gem.summary = "Deploy Ruby on Rails applications with Capistrano to Windows servers"
  gem.description = "This gem modifies capistrano recipes to allow deploys to windows machines.\nSeveral nuances such as the lack of symlinks make the deploy a little different, but it's better than doing it by hand.\nSee the github page for instruction on how to set up Windows to get it ready for a deploy."
  gem.email = "edward.anderson@scimedsolutions.com"
  gem.authors = ["Edward Anderson"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "capistrano-windows-server #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
