module PM

# A Trigger performs an action when it sees a particular array of bytes.
# Instruments have zero or more triggers. The action is a symbol that gets
# sent to PM::PatchMaster.
class Trigger

  attr_accessor :bytes, :block, :text

  def initialize(bytes, block)
    @bytes, @block = bytes, block
  end

  def method_missing(sym, *args)
    PM::PatchMaster.instance.send(sym, *args)
  end

  # If +bytes+ matches our +@bytes+ array then run +block+.
  def signal(bytes)
    if bytes == @bytes
      block.call
    end
  end

  def to_s
    "Trigger(#{@bytes.inspect} => #{text ? text.gsub(/\n/, '; ') : ''})"
  end
end
end
