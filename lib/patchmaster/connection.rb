require 'patchmaster/consts'
require 'patchmaster/formatter'

module PM
  # A Connection connects an InputInstrument to an OutputInstrument. Whenever
  # MIDI data arrives at the InputInstrument it is optionally modified or
  # filtered, then the remaining modified data is sent to the
  # OutputInstrument.
  class Connection
    attr_accessor :input, :input_chan, :output, :output_chan,
                  :bank_msb, :bank_lsb, :pc_prog, :zone, :xpose, :filter

    # If input_chan is nil than all messages from input will be sent to
    # output.
    #
    # All channels (input_chan, output_chan, etc.) are 1-based here but are
    # turned into 0-based channels for later use.
    def initialize(input, input_chan, output, output_chan, filter = nil, opts = {})
      @input = input
      @input_chan = input_chan
      @output = output
      @output_chan = output_chan
      @filter = filter
      @bank_msb = opts[:bank_msb]
      @bank_lsb = opts[:bank_lsb]
      @pc_prog = opts[:pc_prog]
      @zone = opts[:zone]
      @xpose = opts[:xpose]

      @input_chan -= 1 if @input_chan
      @output_chan -= 1 if @output_chan
    end

    def start(start_messages = nil)
      messages = []
      messages += start_messages if start_messages
      messages << [CONTROLLER + @output_chan, CC_BANK_SELECT_MSB, @bank_msb] if @bank_msb
      messages << [CONTROLLER + @output_chan, CC_BANK_SELECT_LSB, @bank_lsb] if @bank_lsb
      messages << [PROGRAM_CHANGE + @output_chan, @pc_prog, 0] if @pc_prog
      midi_out(messages) unless messages.empty?
      @input.add_connection(self)
    end

    def stop(stop_messages = nil)
      midi_out(stop_messages) if stop_messages
      @input.remove_connection(self)
    end

    def accept_from_input?(messages)
      return true if @input_chan.nil?
      return true unless messages.channel?

      messages.channel == @input_chan
    end

    # Returns true if the +@zone+ is nil (allowing all notes throught) or if
    # +@zone+ is a Range and +note+ is inside +@zone+.
    def inside_zone?(note)
      @zone.nil? || @zone.include?(note)
    end

    # The workhorse. Ignore messages that aren't from our input, or are
    # outside the zone. Change to output channel. Filter.
    #
    # Note that running bytes are not handled.
    #
    # Finally, we go through gyrations to avoid duping bytes unless they are
    # actually modified in some way.
    def midi_in(messages)
      messages
        .map { |event| event[:message][0, 3] }
        .select { |msg| accept_from_input?(msg) }
        .each { |msg| do_midi_in(msg) }
    end

    def do_midi_in(message)
      message_duped = false

      high_nibble = message.high_nibble
      case high_nibble
      when NOTE_ON, NOTE_OFF, POLY_PRESSURE
        return unless inside_zone?(message[1])

        if message[0] != high_nibble + @output_chan || (@xpose && @xpose != 0)
          message = message.dup
          message_duped = true
        end

        message[0] = high_nibble + @output_chan
        message[1] = ((message[1] + @xpose) & 0xff) if @xpose
      when CONTROLLER, PROGRAM_CHANGE, CHANNEL_PRESSURE, PITCH_BEND
        if message[0] != high_nibble + @output_chan
          message = message.dup
          message_duped = true
          message[0] = high_nibble + @output_chan
        end
      end

      # We can't tell if a filter will modify the message, so we have to assume
      # they will be. If we didn't, we'd have to rely on the filter duping the
      # message and returning the dupe.
      if @filter
        message = message.dup unless message_duped
        message = @filter.call(self, message)
      end

      return unless message&.size&.positive?

      midi_out([message])
    end

    def midi_out(messages)
      @output.midi_out(messages)
    end

    def pc?
      @pc_prog != nil
    end

    def to_s
      str = "#{@input.name} ch #{@input_chan ? @input_chan + 1 : 'all'} -> #{@output.name} ch #{@output_chan + 1}"
      str << "; pc #{@pc_prog}" if pc?
      str << "; xpose #{@xpose}" if @xpose
      str << "; zone #{Formatter.note_num_to_name(@zone.begin)}..#{Formatter.note_num_to_name(@zone.end)}" if @zone
      str
    end
  end
end
