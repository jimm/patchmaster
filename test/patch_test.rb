require 'test_helper'

class PatchTest < Test::Unit::TestCase

  def setup
    @pm = PM::PatchMaster.instance

    @in_instrument = PM::InputInstrument.new(:tin, 'test_in', 0, true)
    @pm.inputs << @in_instrument

    @out_instrument = PM::OutputInstrument.new(:tout, 'test_out', 0, true)
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
    second_in_instrument = PM::InputInstrument.new(:tin2, '', 0, true)
    @patch << PM::Connection.new(second_in_instrument, nil, nil, nil)
    inputs = @patch.inputs
    assert_equal 2, inputs.size
    assert inputs.include?(@in_instrument)
    assert inputs.include?(second_in_instrument)
  end
end
