module PM

# A CodeKey holds a block or proc and remembers what key it is assigned to.
class CodeKey

  attr_accessor :key, :block_or_proc

  def initialize(key, proc = nil, &block)
    @key, @block_or_proc = key, proc || block
  end

  def call
    @block_or_proc.call
  end
end
end
