module PM

class Patch

  attr_accessor :name, :connections, :start_bytes

  def initialize(name, start_bytes=nil)
    @name = name
    @connections = []
    @start_bytes = start_bytes
    @running = false
  end

  def <<(conn)
    @connections << conn
  end

  def inputs
    @connections.map(&:input).uniq
  end

  # Send start_bytes to each connection, then spawn a new thread that
  # receives input and passes it on to each connection.
  def start
    @connections.each { |conn| conn.start(@start_bytes) }
    @running = true
  end

  def running?
    @running
  end

  def stop
    if @running
      @running = false
      @connections.map(&:stop)
    end
  end
end

end # PM
