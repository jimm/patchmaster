# frozen_string_literal: true

require 'patchmaster/consts'

module PM
  # A Connection connects an InputInstrument to an OutputInstrument. Whenever
  # MIDI data arrives at the InputInstrument it is optionally modified or
  # filtered, then the remaining modified data is sent to the
  # OutputInstrument.
  class Connection
    attr_accessor :input, :input_chan, :output, :output_chan,
                  :bank, :pc_prog, :zone, :xpose, :filter

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
      @bank = opts[:bank]
      @pc_prog = opts[:pc_prog]
      @zone = opts[:zone]
      @xpose = opts[:xpose]

      @input_chan -= 1 if @input_chan
      @output_chan -= 1 if @output_chan
    end

    def start(start_bytes = nil)
      bytes = []
      bytes += start_bytes if start_bytes
      # Bank select uses MSB if we're only sending one byte
      bytes += [CONTROLLER + @output_chan, CC_BANK_SELECT + 32, @bank] if @bank
      bytes += [PROGRAM_CHANGE + @output_chan, @pc_prog] if @pc_prog
      midi_out(bytes) unless bytes.empty?
      @input.add_connection(self)
    end

    def stop(stop_bytes = nil)
      midi_out(stop_bytes) if stop_bytes
      @input.remove_connection(self)
    end

    def accept_from_input?(bytes)
      return true if @input_chan.nil?
      return true unless bytes.channel?

      bytes.channel == @input_chan
    end

    # Returns true if the +@zone+ is nil (allowing all notes throught) or if
    # +@zone+ is a Range and +note+ is inside +@zone+.
    def inside_zone?(note)
      @zone.nil? || @zone.include?(note)
    end

    # The workhorse. Ignore bytes that aren't from our input, or are outside
    # the zone. Change to output channel. Filter.
    #
    # Note that running bytes are not handled. I'm not yet sure how RtMidi
    # handles running bytes, tbh.
    #
    # Finally, we go through gyrations to avoid duping bytes unless they are
    # actually modified in some way.
    def midi_in(bytes)
      return unless accept_from_input?(bytes)

      bytes_duped = false

      high_nibble = bytes.high_nibble
      case high_nibble
      when NOTE_ON, NOTE_OFF, POLY_PRESSURE
        return unless inside_zone?(bytes[1])

        if bytes[0] != high_nibble + @output_chan || (@xpose && @xpose != 0)
          bytes = bytes.dup
          bytes_duped = true
        end

        bytes[0] = high_nibble + @output_chan
        bytes[1] = ((bytes[1] + @xpose) & 0xff) if @xpose
      when CONTROLLER, PROGRAM_CHANGE, CHANNEL_PRESSURE, PITCH_BEND
        if bytes[0] != high_nibble + @output_chan
          bytes = bytes.dup
          bytes_duped = true
          bytes[0] = high_nibble + @output_chan
        end
      end

      # We can't tell if a filter will modify the bytes, so we have to assume
      # they will be. If we didn't, we'd have to rely on the filter duping the
      # bytes and returning the dupe.
      if @filter
        unless bytes_duped
          bytes = bytes.dup
          true
        end
        bytes = @filter.call(self, bytes)
      end

      return unless bytes&.size&.positive?

      midi_out(bytes)
    end

    def midi_out(bytes)
      @output.midi_out(bytes)
    end

    def pc?
      @pc_prog != nil
    end

    def note_num_to_name(n)
      oct = (n / 12) - 1
      note = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'][n % 12]
      "#{note}#{oct}"
    end

    def to_s
      str = "#{@input.name} ch #{@input_chan ? @input_chan + 1 : 'all'} -> #{@output.name} ch #{@output_chan + 1}"
      str << "; pc #{@pc_prog}" if pc?
      str << "; xpose #{@xpose}" if @xpose
      str << "; zone #{note_num_to_name(@zone.begin)}..#{note_num_to_name(@zone.end)}" if @zone
      str
    end
  end
end
