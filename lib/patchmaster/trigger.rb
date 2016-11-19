module PM

# A Trigger executes code when it sees a particular array of messages.
# Instruments have zero or more triggers.
#
# Since we want to save them to files, we store the text representation as
# well.
class Trigger

  attr_accessor :messages, :code_chunk

  def initialize(messages, code_chunk)
    @messages, @code_chunk = messages, code_chunk
  end

  def method_missing(sym, *args)
    PM::PatchMaster.instance.send(sym, *args)
  end

  # If +messages+ matches our +@messages+ array then run +@code_chunk+.
  def signal(messages)
    if messages == @messages
      pm = PM::PatchMaster.instance
      @code_chunk.run(pm)
      pm.gui.refresh if pm.gui
    end
  end

  def to_s
    "#{@messages.inspect} => #{(@code_chunk.text || '# no block text found').gsub(/\n\s*/, '; ')}"
  end
end
end
