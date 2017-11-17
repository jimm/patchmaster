module PM

# A CodeKey holds a CodeChunk and remembers what key it is assigned to.
class CodeKey

  attr_accessor :key, :code_chunk

  def initialize(key, code_chunk)
    @key, @code_chunk = key, code_chunk
  end

  def run
    @code_chunk.run
  end
end
end
