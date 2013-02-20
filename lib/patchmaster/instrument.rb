require 'midi-eye'

# Ports are UniMIDI inputs or outputs.
module PM

class Instrument

  attr_reader :sym, :name, :port_num, :port

  def initialize(sym, name, port_num, port)
    @sym, @name, @port_num, @port = sym, name, port_num, port
    @name ||= @port.name if @port
  end

end

# When a connection is started, it adds itself to this InputInstrument's
# +@connections+. When it ends, it removes itself.
class InputInstrument < Instrument

  attr_accessor :connections, :triggers
  attr_reader :listener

  # If +port+ is nil (the normal case), creates either a real or a mock port
  def initialize(sym, name, port_num, use_midi=true)
    super(sym, name, port_num, input_port(port_num, use_midi))
    @connections = []
    @triggers = []
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
    @port.clear_buffer
    @listener = MIDIEye::Listener.new(@port).listen_for { |event| midi_in(event[:message].to_bytes) }
    @listener.run(:background => true)
  end

  def stop
    PatchMaster.instance.debug("instrument #{name} stop")
    @port.clear_buffer
    if @listener
      @listener.close
      @listener = nil
    end
  end

  # Passes MIDI bytes on to triggers and to each output connection.
  def midi_in(bytes)
    @triggers.each { |trigger| trigger.signal(bytes) }
    @connections.each { |conn| conn.midi_in(bytes) }
  end

  private

  def input_port(port_num, use_midi=true)
    if use_midi
      UniMIDI::Input.all[port_num].open
    else
      MockInputPort.new(port_num)
    end
  end

end

class OutputInstrument < Instrument

  def initialize(sym, name, port_num, use_midi=true)
    super(sym, name, port_num, output_port(port_num, use_midi))
  end

  def midi_out(bytes)
    @port.puts bytes
  end

  private

  def output_port(port_num, use_midi)
    if use_midi
      UniMIDI::Output.all[port_num].open
    else
      MockOutputPort.new(port_num)
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

  # add this class to the Listener class' known input types
  MIDIEye::Listener.input_types << self 

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
