require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems'
require 'rubygems/package_task'

HERE = File.dirname(__FILE__)
PROJECT_NAME = 'patchmaster'
GEM_VERSION = '0.0.4'
GEM_DATE = Time.now.strftime('%Y-%m-%d')

task :default => [:package]

Rake::TestTask.new do |t|
  t.libs << File.join(HERE, 'test')
  t.libs << File.join(HERE, 'lib')
  t.ruby_opts << '-rubygems'
  t.pattern = "test/**/*_test.rb"
end

Rake::RDocTask.new do | rd |
    rd.main = 'README.rdoc'
    rd.title = 'PatchMaster'
    rd.rdoc_files.include('README.rdoc', 'TODO.rdoc', 'lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name        = PROJECT_NAME
  s.version     = GEM_VERSION
  s.date        = GEM_DATE
  s.summary     = "Realtime MIDI setup configuration and MIDI filtering"
  s.description = <<EOS
PatchMaster is realtime MIDI performance software that alloweds a musician
to totally reconfigure a MIDI setup instantaneously and modify the MIDI data
while it's being sent.
EOS
  s.author      = "Jim Menard"
  s.email       = 'jim@jimmenard.com'
  s.executables << PROJECT_NAME
  s.files       = FileList["bin/*", "lib/**/*"].to_a
  s.test_files  = FileList["test/**/test*.rb"].to_a
  s.homepage    = "https://github.com/jimm/#{PROJECT_NAME}"
  s.add_runtime_dependency 'midi-eye'
  s.license     = 'Ruby'
end

# Creates a :package task (also named :gem). Also useful are :clobber_package
# and :repackage.
Gem::PackageTask.new(spec) do |package|
end

desc "Publish the gem to RubyGems.org"
task :publish => [:rdoc, :package] do
  system "gem push pkg/#{PROJECT_NAME}-#{GEM_VERSION}.gem"
end

desc "Clean up rdoc and packages"
task :clean => [:clobber_rdoc, :clobber_package]
