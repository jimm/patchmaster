module PM
  # Filters are blocks of code or procs executed by a Connection to modify
  # incoming MIDI bytes.
  class Filter
    attr_accessor :block_or_proc

    def initialize(proc = nil, &block)
      @block_or_proc = proc || block
    end

    def call(conn, bytes)
      @block_or_proc.call(conn, bytes)
    end
  end
end
