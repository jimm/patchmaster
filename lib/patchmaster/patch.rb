module PM

class Patch

  attr_accessor :name, :connections, :start_bytes, :stop_bytes

  def initialize(name, start_bytes=nil, stop_bytes=nil)
    @name, @start_bytes, @stop_bytes = name, start_bytes, stop_bytes
    @connections = []
    @running = false
  end

  def <<(conn)
    @connections << conn
  end

  def inputs
    @connections.map(&:input).uniq
  end

  # Send start_bytes to each connection.
  def start
    unless @running
      @connections.each { |conn| conn.start(@start_bytes) }
      @connections.map(&:input).uniq.each { |input| input.start }
      @running = true
    end
  end

  def running?
    @running
  end

  # Send stop_bytes to each connection, then call #stop on each connection.
  def stop
    if @running
      @running = false
      @connections.each { |conn| conn.stop(@stop_bytes) }
      @connections.map(&:input).uniq.each { |input| input.stop }
    end
  end
end
end
