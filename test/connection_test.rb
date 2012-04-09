require 'test_helper'

class ConnectionTest < PMTest

  def setup
    @in_device = PM::InputDevice.new('test_in', 0, true)
    @out_device = PM::OutputDevice.new('test_out', 0, true)
    @options = {:pc_prog => 3, :zone => (40..60), :xpose => 12}
    @conn = PM::Connection.new(@in_device, nil, @out_device, 2, nil, @options)
  end

  def test_connection_start_attaches_self_to_input
    assert @in_device.connections.empty?
    @conn.start
    assert_equal 1, @in_device.connections.size
    assert_equal @conn, @in_device.connections.first
  end

  def test_connection_stop_detaches_self_from_input
    @conn.start
    @conn.stop
    assert @in_device.connections.empty?
  end

  def test_inside_zone
    assert !@conn.inside_zone?(39)
    assert @conn.inside_zone?(40)
    assert @conn.inside_zone?(60)
    assert !@conn.inside_zone?(61)
  end

  def test_everything_inside_zone_when_zone_nil
    @conn.zone = nil
    assert @conn.inside_zone?(1)
    assert @conn.inside_zone?(127)
  end

  def test_out_of_zone_no_bytes_sent
    @conn.midi_in([PM::NOTE_ON, 3, 127])
    assert @out_device.port.buffer.empty?,
      'output port should be empty because note is out of range'
  end

  def test_output_sent_to_output_channel
    @conn.xpose = 0
    @conn.midi_in([PM::NOTE_ON + 1, 40, 127])
    assert_equal [PM::NOTE_ON + 1, 40, 127], @out_device.port.buffer

    @out_device.port.buffer = []
    @conn.midi_in([PM::NOTE_ON, 40, 127])
    assert_equal [PM::NOTE_ON + 1, 40, 127], @out_device.port.buffer

    @out_device.port.buffer = []
    @conn.midi_in([PM::CONTROLLER + 15, 1, 2])
    assert_equal [PM::CONTROLLER + 1, 1, 2], @out_device.port.buffer
  end

  def test_transpose
    assert_equal 12, @conn.xpose
    @conn.midi_in([PM::NOTE_ON + 1, 40, 127])
    assert_equal [PM::NOTE_ON + 1, 52, 127], @out_device.port.buffer
  end

  def test_prog_sent
    assert_equal 3, @conn.pc_prog
    @conn.start
    assert_equal [PM::PROGRAM_CHANGE + @conn.output_chan, 3], @out_device.port.buffer
  end

  def test_filter
    filter_block = lambda { |conn, bytes| bytes.map(&:succ) }
    filter = PM::Filter.new(filter_block, nil)
    conn = PM::Connection.new(@in_device, nil, @out_device, 2, filter, @options)
    conn.midi_in([1, 2, 3])
    assert_equal [2, 3, 4], @out_device.port.buffer
  end

  def test_note_num_to_name
    assert_equal "C4", @conn.note_num_to_name(PM::C4)
  end

  def test_to_s
    assert_equal "test_in ch all -> test_out ch 2; pc 3; xpose 12; zone #{@conn.note_num_to_name(40)}..#{@conn.note_num_to_name(60)}", @conn.to_s
  end

end
