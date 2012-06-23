require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems'
require 'rubygems/package_task'

HERE = File.dirname(__FILE__)
PROJECT_NAME = 'patchmaster'
GEM_VERSION = '0.0.7'
GEM_DATE = Time.now.strftime('%Y-%m-%d')
WEB_SERVER = 'jimm.textdriven.com'
WEB_DIR = 'domains/patchmaster.org'
LOCAL_HTML_TARGET = "/Library/WebServer/Documents"
LOCAL_CGI_TARGET = "/Library/WebServer/CGI-Executables"

# Default is defined below after namespace definitions.

Rake::TestTask.new do |t|
  t.libs << File.join(HERE, 'test')
  t.libs << File.join(HERE, 'lib')
  t.ruby_opts << '-rubygems'
  t.pattern = "test/**/*_test.rb"
end

doc_ns = namespace :doc do
  Rake::RDocTask.new do | rd |
    rd.main = 'README.rdoc'
    rd.title = 'PatchMaster'
    rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
  end
end

spec = Gem::Specification.new do |s|
  s.name        = PROJECT_NAME
  s.version     = GEM_VERSION
  s.date        = GEM_DATE
  s.summary     = "Realtime MIDI setup configuration and MIDI filtering"
  s.description = <<EOS
PatchMaster is a MIDI processing and patching system. It allows a musician to
reconfigure a MIDI setup instantaneously and modify the MIDI data in real time.
EOS
  s.author      = "Jim Menard"
  s.email       = 'jim@jimmenard.com'
  s.executables << PROJECT_NAME
  s.files       = FileList["bin/*", "lib/**/*"].to_a
  s.test_files  = FileList["test/**/test*.rb"].to_a
  s.homepage    = "http://www.patchmaster.org/"
  s.add_runtime_dependency 'midi-eye'
  s.license     = 'Ruby'
end

gem_ns = namespace :gem do

  # Creates a :package task (also named :gem). Also useful are
  # :clobber_package and :repackage.
  Gem::PackageTask.new(spec) do |package|
  end

  desc "Publish the gem to RubyGems.org"
  task :publish => [doc_ns[:rdoc], :package] do
    system "gem push pkg/#{PROJECT_NAME}-#{GEM_VERSION}.gem"
  end
end

namespace :web do
  desc "Export Org-mode files to HTML"
  task :build do
    system("/Applications/Emacs.app/Contents/MacOS/Emacs --batch --load ~/.emacs --find-file www/org/file_format.org --eval '(org-publish (assoc \"patchmaster\" org-publish-project-alist) t)'")
  end

  desc "Publish the Web site (does not call web:build)"
  task :publish do
    system "rsync -qrlpt --del --exclude=.textdrive www/public_html #{WEB_SERVER}:#{WEB_DIR}"
  end

  desc "Copy everything to local Mac Web server"
  task :local do
    system("rm -rf #{LOCAL_HTML_TARGET}/* #{LOCAL_CGI_TARGET}/*")
    system("cp -r www/public_html/* #{LOCAL_HTML_TARGET}")
  end
end

desc "Clean up rdoc, packages, and HTML generated from Org-mode files"
task :clean => [doc_ns[:clobber_rdoc], gem_ns[:clobber_package]] do
  Dir["www/org/*.org"].each do |f|
    html = f.sub(/org/, 'public_html').sub(/\.org$/, '.html')
    File.delete(f.sub(/org/, 'public_html').sub(/\.org$/, '.html')) if File.exist?(html)
  end
end

task :default => [gem_ns[:package]]
