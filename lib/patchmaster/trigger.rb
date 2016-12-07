require 'patchmaster/formatter'

module PM

# A Trigger executes code when it sees a particular message. Instruments
# have zero or more triggers.
class Trigger

  attr_accessor :message, :block_or_proc

  def initialize(message, proc = nil, &block)
    @message, @block_or_proc = message, proc || block
  end

  def method_missing(sym, *args)
    PM::PatchMaster.instance.send(sym, *args)
  end

  # If +message+ matches our +@message+ then run +@block_or_proc+.
  def signal(message)
    if message == @message
      pm = PM::PatchMaster.instance
      @block_or_proc.call(pm)
      pm.gui.refresh if pm.gui
    end
  end

  def to_s
    "[#{Formatter.to_s(@message)}] => #{@block_or_proc}"
  end
end
end
