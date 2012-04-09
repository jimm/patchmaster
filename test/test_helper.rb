require 'test/unit'
require 'patchmaster'

# For all tests, make sure mock I/O MIDI ports are used.
PM::PatchMaster.instance.no_midi!

module PM

# To help with testing, we replace MockInputPort#gets_data and
# MockOutputPort#puts with versions that send what we want and save what is
# received.
class MockInputPort

  attr_accessor :data_to_send

  def gets_data
    retval = @data_to_send || []
    @data_to_send = []
    retval
  end
end

class MockOutputPort

  attr_accessor :buffer

  def initialize
    @buffer = []
  end

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
    midi_out(@output, bytes)
  end

end

class PMTest < Test::Unit::TestCase

  # Data comes out of UniMIDI::Input#gets_ata as an array of arrays of MIDI
  # bytes.
  def midi_data(*bytes)
    [bytes]
  end
end
