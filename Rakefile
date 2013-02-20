require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems'
require 'rubygems/package_task'

HERE = File.dirname(__FILE__)
PROJECT_NAME = 'patchmaster'
GEM_VERSION = '1.0.0'
GEM_DATE = Time.now.strftime('%Y-%m-%d')
WEB_SERVER = 'jimmenard.com'
WEB_DIR = 'webapps/patchmaster'
LOCAL_HTML_TARGET = "/tmp/patchmaster"
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
    system("/Applications/Emacs.app/Contents/MacOS/Emacs --batch --load ~/.emacs --find-file www/org/file_format.org --eval '(org-publish (assoc \"patchmaster\" org-publish-project-alist) t)'") if web_build_needed?
  end

  desc "Publish the Web site"
  task :publish => :build do
    system "rsync -qrlpt --filter='exclude .DS_Store' --del www/public_html/ #{WEB_SERVER}:#{WEB_DIR}"
  end

  desc "Copy everything to local static site in /tmp/patchmaster"
  task :local => :build do
    require 'fileutils'
    FileUtils.rm_rf LOCAL_HTML_TARGET
    FileUtils.mkdir_p LOCAL_HTML_TARGET
    FileUtils.cp "www/public_html/style.css", LOCAL_HTML_TARGET
    FileUtils.cp_r "www/public_html/images", LOCAL_HTML_TARGET

    header = IO.read('www/public_html/header.html')
    Dir['www/public_html/*.html'].each do |path|
      base = File.basename(path)
      next if base == 'header.html'

      contents = IO.read(path)
      contents.sub!('<!--#include virtual="header.html"-->', header)
      contents.sub!(/(loc = window\.location\.pathname;)/, '\1 if (loc.indexOf("/tmp/patchmaster") == 0) { loc = loc.substring(16); console.log(loc); }')
      IO.write(File.join(LOCAL_HTML_TARGET, File.basename(path)), contents)
    end
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
