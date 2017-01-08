require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems'
require 'rubygems/package_task'

HERE = File.dirname(__FILE__)
PROJECT_NAME = 'patchmaster'
GEM_VERSION = '1.2.3'
GEM_DATE = Time.now.strftime('%Y-%m-%d')
WEB_SERVER = 'jimmenard.com'
WEB_DIR = "webapps/#{PROJECT_NAME}"
LOCAL_HTML_TARGET = "/tmp/#{PROJECT_NAME}"
LOCAL_CGI_TARGET = "/Library/WebServer/CGI-Executables"

ORGS = Dir[File.join(HERE, 'www/org/*.org')]

def html_for(orgfile)
  File.join(HERE, 'www/public_html', File.basename(orgfile)).sub(/\.org$/, '.html')
end

def web_build_needed?
  ORGS.detect do |orgfile|
    htmlfile = html_for(orgfile)
    File.mtime(htmlfile) < File.mtime(orgfile)
  end
end

# Default is defined below after namespace definitions.

Rake::TestTask.new do |t|
  t.libs << File.join(HERE, 'test')
  t.libs << File.join(HERE, 'lib')
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
  s.homepage    = "http://www.#{PROJECT_NAME}.org/"
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
  desc "Build the site files"
  task :build do
    system("cd site && jekyll build")
  end

  desc "Publish the Web site"
  task :publish => :build do
    system("rsync -qrlpt --filter='exclude .DS_Store' --del site/_site/ #{WEB_SERVER}:#{WEB_DIR}")
  end

  desc "Serve the site locally"
  task :server do
    system("jekyll server")
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
