require 'patchmaster'
require 'irb'
require 'tempfile'

$dsl = nil

# For bin/patchmaster. Does nothing
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

def patch
  dsl.instance_variable_get(:@patch)
end

def clear
  patch.stop
  patch.connections = []
  patch.start
end

def pm_help
  puts <<EOS
input  num, :sym[, name]                          define an input instrument
output num, :sym[, name]                          define an output instrument
conn :in_sym, [chan|nil], :out_sym, [chan|nil]    create a connection
xpose num                                         set transpose for conn
zone zone_def                                     set zone for conn
clear                                             remove all connections
panic                                             panic
panic!                                            panic plus note-offs
EOS
end

def panic!
  PM::PatchMaster.instance.panic(true)
end

def method_missing(sym, *args)
  pm = PM::PatchMaster.instance
  if dsl.respond_to?(sym)
    patch.stop
    dsl.send(sym, *args)
    if sym == :input || sym == :in
      pm.instance.inputs.last.start
    end
    patch.start
  elsif pm.respond_to?(sym)
    pm.send(sym, *args)
  else
    super
  end
end

def start_patchmaster_irb
  f = Tempfile.new('patchmaster')
  f.write <<EOS
  IRB.conf[:PROMPT][:CUSTOM] = {
    :PROMPT_I=>"PatchMaster:%03n:%i> ",
    :PROMPT_N=>"PatchMaster:%03n:%i> ",
    :PROMPT_S=>"PatchMaster:%03n:%i%l ",
    :PROMPT_C=>"PatchMaster:%03n:%i* ",
    :RETURN=>"=> %s\n"
  }
  IRB.conf[:PROMPT_MODE] = :CUSTOM

  puts 'PatchMaster loaded'
  puts 'Type "pm_help" for help'
EOS
  f.close
  ENV['IRBRC'] = f.path
  IRB.start
  f.unlink
end
