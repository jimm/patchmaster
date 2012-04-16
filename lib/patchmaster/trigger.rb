module PM

# A Trigger performs an action when it sees a particular array of bytes.
# Instruments have zero or more triggers. The action is a symbol that gets
# sent to PM::PatchMaster.
class Trigger

  attr_accessor :action_sym, :bytes

  def initialize(action_sym, bytes)
    @action_sym, @bytes = action_sym, bytes
  end

  # If +bytes+ matches our +@bytes+ array then send +action_sym+ to the
  # PatchMaster instance.
  def signal(bytes)
    if bytes == @bytes
      PatchMaster.instance.send(action_sym)
    end
  end

  def to_s
    "#{@bytes.inspect} => :#{@action_sym}"
  end
end
end
