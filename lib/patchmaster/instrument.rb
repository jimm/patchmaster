# Ports are Portmidi inputs or outputs.
module PM
  class Instrument
    attr_reader :sym, :name, :port_num, :port

    def initialize(sym, name, port_num, port)
      @sym, @name, @port_num, @port = sym, name, port_num, port
      @name ||= sym.to_s
    end
  end

  # When a connection is started, it adds itself to this InputInstrument's
  # +@connections+. When it ends, it removes itself.
  class InputInstrument < Instrument

    attr_accessor :connections, :triggers
    attr_reader :listener

    # If +port+ is nil (the normal case), creates either a real or a mock port
    def initialize(sym, name, port_num, use_midi=true)
      super(sym, name, port_num,
            use_midi ? Portmidi::Input.new(port_num) : MockInputPort.new(port_num))
      @connections = []
      @triggers = []
      @listener = nil
    end

    def add_connection(conn)
      @connections << conn
    end

    def remove_connection(conn)
      @connections.delete(conn)
    end

    # Poll for more MIDI input and process it.
    def start
      return if @listener
      PatchMaster.instance.debug("instrument #{name} start")
      @listener = Thread.new {
        while true
          if @port.poll
            midi_in(@port.read)
          end
          sleep 0.01
        end
      }
    end

    def stop
      return unless @listener
      PatchMaster.instance.debug("instrument #{name} stop")
      @listener.exit
      @listener = nil
    end

    # Passes MIDI messages on to triggers and to each output connection.
    def midi_in(messages)
      @triggers.each { |trigger| messages.each {|m| trigger.signal(m)} }
      @connections.each { |conn| conn.midi_in(messages) }
    end
  end

  class OutputInstrument < Instrument

    def initialize(sym, name, port_num, use_midi=true)
      super(sym, name, port_num,
            use_midi ? Portmidi::Output.new(port_num) : MockOutputPort.new(port_num))
    end

    def midi_out(messages)
      messages.each do |msg|
        @port.write_short(msg[0], msg[1] || 0, msg[2] || 0)
      end
    end
  end

  class MockInputPort
    attr_reader :name

    def initialize(port_num)
    end

    def poll
    end
  end

  class MockOutputPort
    attr_reader :name

    def initialize(port_num)
      @buffer = []
    end

    def write_short(status, data1, data2)
      @buffer << [status, data1, data2]
    end

    def clear_buffer
      @buffer = []
    end
  end
end
