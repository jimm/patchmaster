module PM

# Filters are blocks of code executed by a Connection to modify incoming
# MIDI bytes. Since we want to save them to files, we store the text
# representation as well.
class Filter

  attr_accessor :block, :text

  def initialize(block, text=nil)
    @block, @text = block, text
  end

  def call(conn, bytes)
    @block.call(conn, bytes)
  end

  def to_s
    @text || '# no block text found'
  end

end
end
