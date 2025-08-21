# frozen_string_literal: true

# A TestConnection records all bytes received and passes them straight
# through.
class TestConnection < PM::Connection
  attr_accessor :bytes_received

  def midi_in(bytes)
    @bytes_received ||= []
    @bytes_received += bytes
    midi_out(bytes)
  end
end
