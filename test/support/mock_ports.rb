# frozen_string_literal: true

# To help with testing, we replace PM::MockInputPort#gets and
# PM::MockOutputPort#puts with versions that send what we want and save what
# is received.
module PM
  class MockInputPort
    attr_accessor :data_to_send

    alias old_initialize initialize
    def initialize(arg)
      @t0 = (Time.now.to_f * 1000).to_i
      @data_to_send = nil
      old_initialize(arg)
    end

    def receive_message(*_bytes)
      retval = @data_to_send || []
      @data_to_send = []
      [{ data: retval, timestamp: (Time.now.to_f * 1000).to_i - @t0 }]
    end

    def stop_receiving; end
  end

  class MockOutputPort
    alias old_puts puts
    def puts(bytes)
      @buffer += bytes
      old_puts(bytes)
    end
  end
end
