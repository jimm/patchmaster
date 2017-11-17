require 'test_helper'

class InstrumentTest < Test::Unit::TestCase

  def setup
    @data = [1, 2, 3]
    @in_instrument = PM::InputInstrument.new(:tin, 'test_in', 0, false)
    @in_instrument.port.data_to_send = @data
    @out_instrument = PM::OutputInstrument.new(:tout, 'test_out', 0, false)
    @conn = TestConnection.new(@in_instrument, nil, @out_instrument, 2)
  end

  def test_name
    assert_equal 'test_in', @in_instrument.name
    @in_instrument.stop
  end

  def test_midi_in_sends_to_connection
    @in_instrument.add_connection(@conn)
    @in_instrument.midi_in(@data)
    assert_equal @data, @conn.bytes_received
  end

  def test_midi_in_sends_to_multiple_connections
    conn2 = TestConnection.new(@in_instrument, nil, PM::OutputInstrument.new(:tout2, 'test_out2', 0, false), 2)
    @in_instrument.add_connection(@conn)
    @in_instrument.add_connection(conn2)

    @in_instrument.midi_in(@data)
    assert_equal @data, @conn.bytes_received
    assert_equal @data, conn2.bytes_received
  end

  def test_output_sends_to_port
    @out_instrument.midi_out(@data)
    assert_equal @data, @out_instrument.port.buffer
  end

  def test_start_starts_thread
    @in_instrument.start
    assert_not_nil @in_instrument.listener, "instrument listener should be created"
    @in_instrument.stop
  end

  def test_stop_stops_thread
    @in_instrument.start
    @in_instrument.stop
    assert_nil @in_instrument.listener, "instrument listener should be destroyed"
  end
end
