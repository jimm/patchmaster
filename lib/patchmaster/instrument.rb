# Ports are Portmidi inputs or outputs.
module PM

class Instrument

  attr_reader :sym, :name, :port_num, :port

  def initialize(sym, name, port_num, port)
    @sym, @name, @port_num, @port = sym, name, port_num, port
    @name ||= sym.to_s
  end

  private

  def open_port(klass, port_num, use_midi=true)
    if use_midi
      klass.new(port_num.to_i)
    else
      MockInputPort.new(port_num)
    end
  end
end

# When a connection is started, it adds itself to this InputInstrument's
# +@connections+. When it ends, it removes itself.
class InputInstrument < Instrument

  attr_accessor :connections, :triggers
  attr_reader :listener, :running

  # If +port+ is nil (the normal case), creates either a real or a mock port
  def initialize(sym, name, port_num, use_midi=true)
    super(sym, name, port_num, # open_port(Portmidi::Input, port_num, use_midi))
          Portmidi::Input.new(port_num.to_i)) # DEBUG
    @connections = []
    @triggers = []
    @listener = nil
    @running = false
  end

  def add_connection(conn)
    @connections << conn
  end

  def remove_connection(conn)
    @connections.delete(conn)
  end

  # Poll for more MIDI input and process it.
  def start
    PatchMaster.instance.debug("instrument #{name} start")
    if !@listener
      @listener = Thread.new {
        while true
          if @port.poll
            midi_in(@port.read)
          end
          sleep 0.01
        end
      }
    end
  end

  def stop
    PatchMaster.instance.debug("instrument #{name} stop")
    if @listener
      @listener.exit
      @listener = nil
    end
  end

  # Passes MIDI messages on to triggers and to each output connection.
  def midi_in(messages)
    @triggers.each { |trigger| trigger.signal(messages) }
    @connections.each { |conn| conn.midi_in(messages) }
  end
end

class OutputInstrument < Instrument

  def initialize(sym, name, port_num, use_midi=true)
    super(sym, name, port_num, open_port(Portmidi::Output, port_num, use_midi))
  end

  def midi_out(messages)
    messages.each do |msg|
      @port.write_short(msg[0], msg[1] || 0, msg[2] || 0)
    end
  end
end

class MockInputPort

  attr_reader :name

  # For MIDIEye::Listener
  def self.is_compatible?(input)
    true
  end

  # Constructor param is ignored; it's required by MIDIEye.
  def initialize(arg)
    @name = "MockInputPort #{arg}"
  end

  def gets
    [{:data => [], :timestamp => 0}]
  end

  def poll
    yield gets
  end

  def clear_buffer
  end
end

class MockOutputPort

  attr_reader :name

  def initialize(port_num)
    @name = "MockOutputPort #{port_num}"
  end

  def puts(data)
  end
end
end
