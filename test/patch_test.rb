require 'test_helper'

class PatchTest < PMTest

  def setup
    @in_device = PM::InputDevice.new('test_in', 0, true)
    @out_device = PM::OutputDevice.new('test_out', 0, true)
    @options = {:pc_prog => 3, :zone => (40..60), :xpose => 12}
    @patch = PM::Patch.new('Untitled')
    @conn = PM::Connection.new(@in_device, nil, @out_device, 2, nil, @options)
    @patch << @conn
  end

  def teardown
    @patch.stop
  end

  def test_start_starts_connections
    @patch.start
    assert_equal @conn, @in_device.connections.first
    @patch.stop
  end

  def test_start_sends_start_bytes
    @patch.start_bytes = [1, 2, 3]
    @patch.start
    @patch.stop
    assert_equal [1, 2, 3], @out_device.port.buffer[0,3]
  end

  def test_inputs
    assert_equal [@in_device], @patch.inputs

    # Add another connection that uses the same input device
    @patch << PM::Connection.new(@in_device, nil, nil, nil)
    assert_equal [@in_device], @patch.inputs

    # Add another connection that uses a different one
    second_in_device = PM::InputDevice.new('', 0, true)
    @patch << PM::Connection.new(second_in_device, nil, nil, nil)
    inputs = @patch.inputs
    assert_equal 2, inputs.size
    assert inputs.include?(@in_device)
    assert inputs.include?(second_in_device)
  end

  def test_start_starts_thread
    @in_device.port.data_to_send = midi_data(4, 5, 6)
    @patch.start
    # FIXME this sleep is a hack to make sure #gets_data is called.
    sleep(0.1)
    @patch.stop
    assert_equal [PM::PROGRAM_CHANGE + 1, 3, 4, 5, 6], @out_device.port.buffer
  end

  def test_stop_stops_thread
    @in_device.port.data_to_send = midi_data(4, 5, 6)
    @patch.start
    # FIXME this sleep is a hack to make sure #gets_data is called.
    sleep(0.1)
    @patch.stop

    # Now send more data and make sure it was not sent
    @in_device.port.data_to_send = midi_data(7, 8, 9)
    assert_equal [PM::PROGRAM_CHANGE + 1, 3, 4, 5, 6], @out_device.port.buffer
  end

end
