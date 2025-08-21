# frozen_string_literal: true

module PM
  # A CodeChunk holds a block of code (lambda, block, proc) and the text that
  # created it as read in from a PatchMaster file.
  class CodeChunk
    attr_accessor :block, :text

    def initialize(block, text = nil)
      @block = block
      @text = text
    end

    def run(*args)
      block.call(*args)
    end

    def to_s
      "#<PM::CodeChunk block=#{block.inspect}, text=#{text.inspect}>"
    end
  end
end
