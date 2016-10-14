require 'test/unit'
require 'patchmaster'

# For all tests, make sure mock I/O MIDI ports are used.
PM::PatchMaster.instance.use_midi = false

module PM

# To help with testing, we replace PM::MockInputPort#gets and
# PM::MockOutputPort#puts with versions that send what we want and save what
# is received.
class MockInputPort

  attr_accessor :data_to_send

  alias_method :old_initialize, :initialize # avoid "method redefined" warning
  def initialize(arg)
    @name = "MockInputPort #{arg}"
    @t0 = (Time.now.to_f * 1000).to_i
    @data_to_send = nil
  end

  alias_method :old_gets, :gets
  def gets
    retval = @data_to_send || []
    @data_to_send = []
    [{:data => retval, :timestamp => (Time.now.to_f * 1000).to_i - @t0}]
  end
end

class MockOutputPort

  attr_accessor :buffer

  alias_method :old_initialize, :initialize
  def initialize(port_num)
    @name = "MockOutputPort #{port_num}"
    @buffer = []
  end

  alias_method :old_puts, :puts
  def puts(bytes)
    @buffer += bytes
  end
end
end

# A TestConnection records all bytes received and passes them straight
# through.
class TestConnection < PM::Connection

  attr_accessor :bytes_received

  def midi_in(bytes)
    @bytes_received ||= []
    @bytes_received += bytes
    midi_out(bytes)
  end

end
