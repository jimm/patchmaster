# frozen_string_literal: true

module PM
  # Filters are blocks of code executed by a Connection to modify incoming
  # MIDI bytes. Since we want to save them to files, we store the text
  # representation as well.
  class Filter
    attr_accessor :code_chunk

    def initialize(code_chunk)
      @code_chunk = code_chunk
    end

    def call(conn, bytes)
      @code_chunk.run(conn, bytes)
    end

    def to_s
      @code_chunk.text || '# no block text found'
    end
  end
end
