require 'test_helper'

class InstrumentTest < PMTest

  def setup
    @data = midi_data(1, 2, 3)
    @in_instrument = PM::InputInstrument.new('test_in', 0, true)
    @in_instrument.port.data_to_send = @data
    @out_instrument = PM::OutputInstrument.new('test_out', 0, true)
    @conn = TestConnection.new(@in_instrument, nil, @out_instrument, 2)
  end

  def test_name
    assert_equal 'test_in', @in_instrument.name
  end

  def test_process_messages_sends_to_connection
    @in_instrument.add_connection(@conn)
    @in_instrument.process_messages
    assert_equal @data.first, @conn.bytes_received
  end

  def test_process_messages_sends_to_multiple_connections
    conn2 = TestConnection.new(@in_instrument, nil, PM::OutputInstrument.new('test_out2', 0, true), 2)
    @in_instrument.add_connection(@conn)
    @in_instrument.add_connection(conn2)

    @in_instrument.process_messages
    assert_equal @data.first, @conn.bytes_received
    assert_equal @data.first, conn2.bytes_received
  end

  def test_output_sends_to_port
    @out_instrument.midi_out(@data.first)
    assert_equal @data.first, @out_instrument.port.buffer
  end
end
