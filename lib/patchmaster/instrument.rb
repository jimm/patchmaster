require 'portmidi'

# Ports are Portmidi inputs or outputs.
module PM
  class Instrument
    attr_reader :sym, :name, :port_num, :port

    def initialize(sym, name, port_num, port)
      @sym = sym
      @name = name
      @port_num = port_num
      @port = port
      @name ||= sym.to_s
    end

    # Given a port number or name and an `io_sym` of `:input` or `:output`,
    # returns the port number of the device. The name comparison is
    # case-insensitive and ignores leading/trailing whitespace. Raises an
    # error if the device is not found by name.
    def name_to_port_num(port_num_or_name, io_sym)
      return port_num_or_name if port_num_or_name.instance_of?(Integer)

      port_num_or_name = port_num_or_name.downcase.strip
      device = Portmidi.devices.detect do
        _1.type == io_sym && _1.name.downcase.strip == port_num_or_name
      end
      raise "No Portmidi #{io_sym} device found online with the name '#{port_num_or_name}'" unless device

      device.device_id
    end
  end

  # When a connection is started, it adds itself to this InputInstrument's
  # +@connections+. When it ends, it removes itself.
  class InputInstrument < Instrument
    attr_accessor :connections, :triggers
    attr_reader :listener

    # If +port+ is nil (the normal case), creates either a real or a mock port
    def initialize(sym, name, port_num_or_name, use_midi = true)
      port_num = if port_num_or_name.instance_of?(String)
                   name_to_port_num(port_num_or_name, :input)
                 else
                   port_num_or_name
                 end
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
      @listener = Thread.new do
        loop do
          midi_in(@port.read) if @port.poll
          sleep 0.01
        end
      end
    end

    def stop
      return unless @listener

      PatchMaster.instance.debug("instrument #{name} stop")
      @listener.exit
      @listener = nil
    end

    # Passes MIDI messages on to triggers and to each output connection.
    def midi_in(messages)
      @triggers.each { |trigger| messages.each { |m| trigger.signal(m) } }
      @connections.each { |conn| conn.midi_in(messages) }
    end
  end

  class OutputInstrument < Instrument
    def initialize(sym, name, port_num_or_name, use_midi = true)
      port_num = if port_num_or_name.instance_of?(String)
                   name_to_port_num(port_num_or_name, :output)
                 else
                   port_num_or_name
                 end
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

    def initialize(port_num); end

    def poll; end
  end

  class MockOutputPort
    attr_reader :name

    def initialize(_port_num)
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
