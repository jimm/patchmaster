require 'test_helper'

class IoTest < PMTest

  def setup
    @data = midi_data(1, 2, 3)
    @in_device = PM::InputDevice.new('test_in', 0, true)
    @in_device.port.data_to_send = @data
    @out_device = PM::OutputDevice.new('test_out', 0, true)
    @conn = TestConnection.new(@in_device, nil, @out_device, 2)
  end

  def test_name
    assert_equal 'test_in', @in_device.name
  end

  def test_gets_data_sends_to_connection
    @in_device.add_connection(@conn)
    @in_device.gets_data
    assert_equal @data.first, @conn.bytes_received
  end

  def test_gets_data_sends_to_multiple_connections
    conn2 = TestConnection.new(@in_device, nil, PM::OutputDevice.new('test_out2', 0, true), 2)
    @in_device.add_connection(@conn)
    @in_device.add_connection(conn2)

    @in_device.gets_data
    assert_equal @data.first, @conn.bytes_received
    assert_equal @data.first, conn2.bytes_received
  end

  def test_output_sends_to_port
    @out_device.midi_out(@data.first)
    assert_equal @data.first, @out_device.port.buffer
  end

end
