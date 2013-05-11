require 'test_helper'

class PatchTest < Test::Unit::TestCase

  def setup
    @pm = PM::PatchMaster.instance

    @in_instrument = PM::InputInstrument.new(:tin, 'test_in', 0, false)
    @pm.inputs << @in_instrument

    @out_instrument = PM::OutputInstrument.new(:tout, 'test_out', 0, false)
    @pm.outputs << @out_instrument

    @options = {:pc_prog => 3, :zone => (40..60), :xpose => 12}
    @patch = PM::Patch.new('Untitled')
    @conn = PM::Connection.new(@in_instrument, nil, @out_instrument, 2, nil, @options)
    @patch << @conn

    @pm.start
  end

  def teardown
    @pm.stop
    @patch.stop
  end

  def test_start_starts_connections
    @patch.start
    assert_equal @conn, @in_instrument.connections.first
    @patch.stop
  end

  def test_start_sends_start_bytes
    @patch.start_bytes = [1, 2, 3]
    @patch.start
    @patch.stop
    assert_equal [1, 2, 3], @out_instrument.port.buffer[0,3]
  end

  def test_stop_sends_stop_bytes
    @patch.start_bytes = nil
    @patch.stop_bytes = [1, 2, 3]
    @patch.start
    @patch.stop
    assert_equal [1, 2, 3], @out_instrument.port.buffer[-3..-1]
  end

  def test_inputs
    assert_equal [@in_instrument], @patch.inputs

    # Add another connection that uses the same input instrument
    @patch << PM::Connection.new(@in_instrument, nil, nil, nil)
    assert_equal [@in_instrument], @patch.inputs

    # Add another connection that uses a different one
    second_in_instrument = PM::InputInstrument.new(:tin2, '', 0, false)
    @patch << PM::Connection.new(second_in_instrument, nil, nil, nil)
    inputs = @patch.inputs
    assert_equal 2, inputs.size
    assert inputs.include?(@in_instrument)
    assert inputs.include?(second_in_instrument)
  end

  def test_all_prog_changes_sent
    conn2 = PM::Connection.new(@in_instrument, nil, @out_instrument, 3, nil, {:pc_prog => 42})
    @patch << conn2

    @patch.start
    assert_equal [PM::PROGRAM_CHANGE + 1, 3, PM::PROGRAM_CHANGE + 2, 42], @out_instrument.port.buffer
  end

  # Tests two connections with non-overlapping zones that go to different
  # channels on the same instrument.
  def test_zones
    @conn.pc_prog = nil
    @conn.zone = (0..PM::Gs4)

    conn2 = PM::Connection.new(@in_instrument, nil, @out_instrument, 3, nil)
    conn2.zone = (PM::A4..127)
    @patch << conn2

    assert_equal (0..68), @conn.zone
    assert_equal (69..127), conn2.zone

    @patch.start

    # Send note in @conn1 zone
    @patch.connections.each { |c| c.midi_in([PM::NOTE_ON + 9, PM::C1, 127]) }
    expected = [PM::NOTE_ON + 1, PM::C2, 127] # transposed, channel 1
    assert_equal expected, @out_instrument.port.buffer

    # Send note in conn2 zone
    @patch.connections.each { |c| c.midi_in([PM::NOTE_ON + 9, PM::C5, 127]) }
    expected += [PM::NOTE_ON + 2, PM::C5, 127] # not transposed, channel 2
    assert_equal expected, @out_instrument.port.buffer

    # Note at top of @conn1 zone
    @patch.connections.each { |c| c.midi_in([PM::NOTE_ON + 9, PM::Gs4, 127]) }
    expected += [PM::NOTE_ON + 1, PM::Gs5, 127] # transposed, channel 1
    assert_equal expected, @out_instrument.port.buffer

    # Note at bottom of conn2 zone
    @patch.connections.each { |c| c.midi_in([PM::NOTE_ON + 9, PM::A4, 127]) }
    expected += [PM::NOTE_ON + 2, PM::A4, 127] # not transposed, channel 2
    assert_equal expected, @out_instrument.port.buffer
  end
end
