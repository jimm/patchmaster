# frozen_string_literal: true

module PM
  class Patch
    attr_accessor :name, :connections, :start_bytes, :stop_bytes

    def initialize(name, start_bytes = nil, stop_bytes = nil)
      @name = name
      @start_bytes = start_bytes
      @stop_bytes = stop_bytes
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
      return if @running

      @connections.each { |conn| conn.start(@start_bytes) }
      @running = true
    end

    def running?
      @running
    end

    # Send stop_bytes to each connection, then call #stop on each connection.
    def stop
      return unless @running

      @running = false
      @connections.each { |conn| conn.stop(@stop_bytes) }
    end
  end
end
