# Ports are UniMIDI inputs or outputs.
module PM

class Instrument

  attr_reader :name, :port_num, :port

  def initialize(name, port_num, port)
    @name, @port_num, @port = name, port_num, port
  end

end

# When a connection is started, it adds itself to this InputInstrument's
# +@connections+. When it ends, it removes itself.
class InputInstrument < Instrument

  attr_accessor :connections

  # If +port+ is nil (the normal case), creates either a real or a mock port
  def initialize(name, port_num, no_midi=false)
    super(name, port_num, input_port(port_num, no_midi))
    @connections = []
  end

  def add_connection(conn)
    @connections << conn
  end

  def remove_connection(conn)
    @connections.delete(conn)
  end

  # Poll for more MIDI input and process it.
  def gets_data
    @port.gets_data.each { |bytes| midi_in(bytes) }
  end

  # Passes MIDI bytes on to each output connection
  def midi_in(bytes)
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
  def gets_data
    []
  end
end

class MockOutputPort
  def puts(data)
  end
end
end
