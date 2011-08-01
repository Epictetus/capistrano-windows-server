# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{capistrano-windows-server}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Edward Anderson"]
  s.date = %q{2011-08-01}
  s.description = %q{This gem modifies capistrano recipes to allow deploys to windows machines.
Several nuances such as the lack of symlinks make the deploy a little different, but it's better than doing it by hand.
See the github page for instruction on how to set up Windows to get it ready for a deploy.}
  s.email = %q{edward.anderson@scimedsolutions.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "capistrano-windows-server.gemspec",
    "lib/capistrano/ext/windows_server.rb"
  ]
  s.homepage = %q{http://github.com/nilbus/capistrano-windows-server}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{Deploy Ruby on Rails applications with Capistrano to Windows servers}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<capistrano>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
    else
      s.add_dependency(%q<capistrano>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    end
  else
    s.add_dependency(%q<capistrano>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
  end
end

