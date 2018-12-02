require 'sinatra'
require 'sinatra/json'
require 'singleton'

# ================================================================
# Helper methods
# ================================================================

def return_status(opts={})
  pm = PM::PatchMaster.instance()
  status = {
    :lists => pm.song_lists.map(&:name),
    :list => pm.song_list.name,
    :songs => pm.song_list.songs.map(&:name),
    :triggers => pm.inputs.collect do |instrument|
      instrument.triggers.collect { |trigger| ":#{instrument.sym} #{trigger.to_s}" }
    end.flatten
  }
  if pm.song
    status[:song] = {
      :name => pm.song.name,
      :patches => pm.song.patches.map(&:name)
    }
    if pm.patch
      status[:patch] = {
        :name => pm.patch.name,
        :connections => pm.patch.connections.collect do |conn|
          {
            :input => conn.input.name,
            :input_chan => conn.input_chan ? conn.input_chan + 1 : 'all',
            :output => conn.output.name,
            :output_chan => conn.output_chan + 1,
            :pc => conn.pc_prog.to_s,
            :zone => conn.zone ? [conn.note_num_to_name(conn.zone.begin),
                                  conn.note_num_to_name(conn.zone.end)] : '',
            :xpose => conn.xpose.to_s,
            :filter => conn.filter.to_s
          }
        end
      }
    end
  end
  json status.merge(opts)
end

# ================================================================
# URL handlers
# ================================================================

class Sinatra::Base
set :run, true
set :root, File.dirname(__FILE__)

not_found do
  path = request.env['REQUEST_PATH']
  unless path == '/favicon.ico'
    $stderr.puts "error: not_found called, request = #{request.inspect}" # DEBUG
    return_status(:message => "No such URL: #{path}")
  end
end

get '/' do
  redirect '/index.html'
end

get '/status' do
  return_status
end

get '/next_patch' do
  pm.next_patch
  return_status
end

get '/prev_patch' do
  pm.prev_patch
  return_status
end

get '/next_song' do
  pm.next_song
  return_status
end

get '/prev_song' do
  pm.prev_song
  return_status
end

get '/panic' do
  # TODO when panic called twice in a row, call panic(true)
  pm.panic
  return_status
end
end

# ================================================================
# GUI class: run method
# ================================================================

module PM
  class Web
    include Singleton

    attr_accessor :port
    attr_reader :pm

    def initialize
      @pm = PM::PatchMaster.instance
      @started = false
    end

    def run
      return if @started

      @pm.start
      @started = true
      Sinatra::Base.set(:port, @port) if @port
      Sinatra::Base.run!
    end
  end
end
