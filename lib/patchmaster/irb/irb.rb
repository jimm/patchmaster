# frozen_string_literal: true

require 'patchmaster'
require 'irb'
require 'tempfile'

$dsl = nil

module PM
  class IRB
    include Singleton

    attr_reader :dsl

    def initialize
      @dsl = PM::DSL.new
      @dsl.song('IRB Song')
      @dsl.patch('IRB Patch')
    end

    # For bin/patchmaster.
    def run
      ::IRB.start
    end
  end
end

def dsl
  PM::IRB.instance.dsl
end

# Return the current (only) patch.
def patch
  dsl.instance_variable_get(:@patch)
end

# Stop and delete all connections.
def clear
  patch.stop
  patch.connections = []
  patch.start
end

def pm_help
  puts IO.read(File.join(File.dirname(__FILE__), 'irb_help.txt'))
end

# The "panic" command is handled by the PM::DSL instance. This version
# (+panic!+) tells that +panic+ to send all all-notes-off messages.
def panic!
  PM::PatchMaster.instance.panic(true)
end

def self.method_missing(sym, *args)
  pm = PM::PatchMaster.instance
  if dsl.respond_to?(sym)
    patch.stop
    dsl.send(sym, *args)
    pm.inputs.last.start if %i[input inp].include?(sym)
    patch.start
  elsif pm.respond_to?(sym)
    pm.send(sym, *args)
  else
    super
  end
end
