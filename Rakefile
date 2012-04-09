require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems'
require 'rubygems/package_task'

HERE = File.dirname(__FILE__)
PROJECT_NAME = 'patchmaster'

task :default => [:package]

Rake::TestTask.new do |t|
  t.libs << File.join(HERE, 'test')
  t.libs << File.join(HERE, 'lib')
  t.ruby_opts << '-rubygems'
  t.pattern = "test/**/*_test.rb"
end

Rake::RDocTask.new do | rd |
    rd.main = 'README.rdoc'
    rd.title = PROJECT_NAME
    rd.rdoc_files.include('README.rdoc', 'TODO.rdoc', 'lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name        = PROJECT_NAME
  s.version     = '0.0.0'
  s.date        = '2012-04-09'
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
  s.add_runtime_dependency 'unimidi'
  s.license     = 'Ruby'
end

# Creates a :package task (also named :gem). Also useful are :clobber_package
# and :repackage.
Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
end

task :publish => [:rdoc, :package] do
  system "gem push"
end

task :clean => [:clobber_rdoc, :clobber_package]
