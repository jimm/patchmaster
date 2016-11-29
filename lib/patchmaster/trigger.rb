module PM

# A Trigger executes code when it sees a particular array of messages.
# Instruments have zero or more triggers.
class Trigger

  attr_accessor :messages, :block_or_proc

  def initialize(messages, proc = nil, &block)
    @messages, @block_or_proc = messages, proc || block
  end

  def method_missing(sym, *args)
    PM::PatchMaster.instance.send(sym, *args)
  end

  # If +messages+ matches our +@messages+ array then run +@block_or_proc+.
  def signal(messages)
    if messages == @messages
      pm = PM::PatchMaster.instance
      @block_or_proc.call(pm)
      pm.gui.refresh if pm.gui
    end
  end

  def to_s
    "#{@messages.inspect} => #{@block_or_proc}"
  end
end
end
