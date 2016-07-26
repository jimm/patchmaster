require 'test_helper'

class ConnectionTest < Test::Unit::TestCase

  def setup
    @in_instrument = PM::InputInstrument.new(:tin, 'test_in', 0, false)
    @out_instrument = PM::OutputInstrument.new(:tout, 'test_out', 0, false)
    @options = {:pc_prog => 3, :zone => (40..60), :xpose => 12}
    @conn = PM::Connection.new(@in_instrument, nil, @out_instrument, 2, nil, @options)
  end

  def test_start_attaches_self_to_input
    assert @in_instrument.connections.empty?
    @conn.start
    assert_equal 1, @in_instrument.connections.size
    assert_equal @conn, @in_instrument.connections.first
  end

  def test_stop_detaches_self_from_input
    @conn.start
    @conn.stop
    assert @in_instrument.connections.empty?
  end

  def test_start_sends_start_bytes
    assert_equal [], @out_instrument.port.buffer
    @conn.start([1, 2, 3])
    assert_equal [1, 2, 3], @out_instrument.port.buffer[0,3]
    @conn.stop
    assert_equal [1, 2, 3], @out_instrument.port.buffer[0,3]
  end

  def test_stop_sends_stop_bytes
    assert_equal [], @out_instrument.port.buffer
    @conn.start
    @conn.stop([4, 5, 6])
    assert_equal [4, 5, 6], @out_instrument.port.buffer[-3..-1]
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

  def test_accept_from_input_filters_input_chan
    @conn.input_chan = 3
    @conn.zone = nil
    (0x80..0xff).each do |status|
      expected = status >= 0xf0 || (status & 0x0f) == 3
      assert_equal expected, @conn.accept_from_input?([status, 0, 0])
    end
    assert @conn.accept_from_input?([0x93, 0, 0])
    assert @conn
  end

  def test_accept_from_input_takes_anything_if_nil_in_chan
    (0x80..0xff).each do |status|
      assert @conn.accept_from_input?([status, 0, 0])
    end
  end

  def test_out_of_zone_no_bytes_sent
    @conn.midi_in([PM::NOTE_ON, 3, 127])
    assert @out_instrument.port.buffer.empty?,
      'output port should be empty because note is out of range'
  end

  def test_output_sent_to_output_channel
    @conn.xpose = 0
    @conn.midi_in([PM::NOTE_ON + 1, 40, 127])
    assert_equal [PM::NOTE_ON + 1, 40, 127], @out_instrument.port.buffer

    @out_instrument.port.buffer = []
    @conn.midi_in([PM::NOTE_ON, 40, 127])
    assert_equal [PM::NOTE_ON + 1, 40, 127], @out_instrument.port.buffer

    @out_instrument.port.buffer = []
    @conn.midi_in([PM::CONTROLLER + 15, 1, 2])
    assert_equal [PM::CONTROLLER + 1, 1, 2], @out_instrument.port.buffer
  end

  def test_transpose
    assert_equal 12, @conn.xpose
    @conn.midi_in([PM::NOTE_ON + 1, 40, 127])
    assert_equal [PM::NOTE_ON + 1, 52, 127], @out_instrument.port.buffer
  end

  def test_prog_sent
    assert_equal 3, @conn.pc_prog
    @conn.start
    assert_equal [PM::PROGRAM_CHANGE + @conn.output_chan, 3], @out_instrument.port.buffer
  end

  def test_bank_sent
    @conn.bank = 2
    @conn.start
    assert_equal [PM::CONTROLLER + @conn.output_chan, PM::CC_BANK_SELECT + 32, 2,
                  PM::PROGRAM_CHANGE + @conn.output_chan, 3],
      @out_instrument.port.buffer
  end

  def test_filter
    filter_block = lambda { |conn, bytes| bytes.map(&:succ) }
    filter = PM::Filter.new(PM::CodeChunk.new(filter_block))
    conn = PM::Connection.new(@in_instrument, nil, @out_instrument, 2, filter, @options)
    conn.midi_in([1, 2, 3])
    assert_equal [2, 3, 4], @out_instrument.port.buffer
  end

  def test_note_num_to_name
    assert_equal "C4", @conn.note_num_to_name(PM::C4)
  end

  def test_to_s
    assert_equal "test_in ch all -> test_out ch 2; pc 3; xpose 12; zone #{@conn.note_num_to_name(40)}..#{@conn.note_num_to_name(60)}", @conn.to_s
  end
end
