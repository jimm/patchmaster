require 'patchmaster'
require 'irb'
require 'tempfile'

$dsl = nil

# For bin/patchmaster. Does nothing.
def run
end

def dsl
  unless $dsl
    $dsl = PM::DSL.new
    $dsl.song("IRB Song")
    $dsl.patch("IRB Patch")
  end
  $dsl
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

# The "panic" command is handled by $dsl. This version tells panic to send
# all all-notes-off messages.
def panic!
  PM::PatchMaster.instance.panic(true)
end

def method_missing(sym, *args)
  pm = PM::PatchMaster.instance
  if dsl.respond_to?(sym)
    patch.stop
    dsl.send(sym, *args)
    if sym == :input || sym == :inp
      pm.inputs.last.start
    end
    patch.start
  elsif pm.respond_to?(sym)
    pm.send(sym, *args)
  else
    super
  end
end

def start_patchmaster_irb(init_file=nil)
  ENV['IRBRC'] = init_file if init_file
  IRB.start
end
