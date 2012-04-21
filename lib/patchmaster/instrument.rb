require 'midi-eye'

# Ports are UniMIDI inputs or outputs.
module PM

class Instrument

  attr_reader :name, :port_num, :port

  def initialize(name, port_num, port)
    @name, @port_num, @port = name, port_num, port
    PatchMaster.instance.debug("instrument #{name} @port = #{@port.inspect}")
  end

end

# When a connection is started, it adds itself to this InputInstrument's
# +@connections+. When it ends, it removes itself.
class InputInstrument < Instrument

  attr_accessor :connections, :triggers

  # If +port+ is nil (the normal case), creates either a real or a mock port
  def initialize(name, port_num, no_midi=false)
    super(name, port_num, input_port(port_num, no_midi))
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
    @listener = MIDIEye::Listener.new(@port).listen_for { |event| midi_in(event[:message].to_bytes) }
    @listener.run(:background => true)
  end

  def stop
    PatchMaster.instance.debug("instrument #{name} stop")
    @listener.close
  end

  # Passes MIDI bytes on to triggers and to each output connection.
  def midi_in(bytes)
    @triggers.each { |trigger| trigger.signal(bytes) }
    @connections.each { |conn| conn.midi_in(bytes) }
  end

  private

  def input_port(port_num, no_midi=false)
    if no_midi
      MockInputPort.new
    else
      UniMIDI::Input.all[port_num].open
    end
  end

end

class OutputInstrument < Instrument

  def initialize(name, port_num, no_midi=false)
    super(name, port_num, output_port(port_num, no_midi))
  end

  def midi_out(bytes)
    @port.puts bytes
  end

  private

  def output_port(port_num, no_midi)
    if no_midi
      MockOutputPort.new
    else
      UniMIDI::Output.all[port_num].open
    end
  end
end

class MockInputPort
  def gets
    [{:data => [], :timestamp => 0}]
  end
end

class MockOutputPort
  def puts(data)
  end
end
end
