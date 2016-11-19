module PM

class Patch

  attr_accessor :name, :connections, :start_messages, :stop_messages

  def initialize(name, start_messages=nil, stop_messages=nil)
    @name, @start_messages, @stop_messages = name, start_messages, stop_messages
    @connections = []
    @running = false
  end

  def <<(conn)
    @connections << conn
  end

  def inputs
    @connections.map(&:input).uniq
  end

  # Send start_messages to each connection.
  def start
    unless @running
      @connections.each { |conn| conn.start(@start_messages) }
      @running = true
    end
  end

  def running?
    @running
  end

  # Send stop_messages to each connection, then call #stop on each connection.
  def stop
    if @running
      @running = false
      @connections.each { |conn| conn.stop(@stop_messages) }
    end
  end
end
end
