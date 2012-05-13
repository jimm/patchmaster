require 'sinatra'
require 'singleton'

set :run, true
set :root, File.dirname(__FILE__)

get '/' do
  erb :index
end

module PM

class SinatraApp

  include Singleton

  def initialize
    @pm = PM::PatchMaster.instance
  end

  def run
    @pm.start
  ensure
    @pm.stop
    @pm.close_debug_file
  end
end
end
