module PM

# A Trigger performs an action when it sees a particular array of bytes.
# Instruments have zero or more triggers. The action is a symbol that gets
# sent to PM::PatchMaster.
#
# Since we want to save them to files, we store the text representation as
# well.
class Trigger

  attr_accessor :bytes, :block, :text

  def initialize(bytes, block)
    @bytes, @block = bytes, block
  end

  def method_missing(sym, *args)
    PM::PatchMaster.instance.send(sym, *args)
  end

  # If +bytes+ matches our +@bytes+ array then run +@block+.
  def signal(bytes)
    if bytes == @bytes
      pm = PM::PatchMaster.instance
      pm.instance_eval &@block
      pm.gui.refresh if pm.gui
    end
  end

  def to_s
    "#{@bytes.inspect} => #{(@text || '# no block text found').gsub(/\n\s*/, '; ')}"
  end
end
end
