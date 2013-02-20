require 'singleton'
require 'delegate'
require 'patchmaster/sorted_song_list'
require 'patchmaster/cursor'

module PM

# Global behavior: master list of songs, list of song lists, stuff like
# that.
#
# Typical use:
#
#   PatchMaster.instance.load("my_pm_dsl_file")
#   PatchMaster.instance.start
#   # ...when you're done
#   PatchMaster.instance.stop
class PatchMaster < SimpleDelegator

  DEBUG_FILE = '/tmp/pm_debug.txt'

  include Singleton

  attr_reader :inputs, :outputs, :all_songs, :song_lists
  attr_reader :messages
  attr_accessor :use_midi
  alias_method :use_midi?, :use_midi
  attr_accessor :gui

  # A Cursor to which we delegate incoming position methods (#song_list,
  # #song, #patch, #next_song, #prev_patch, etc.)
  attr_reader :cursor

  def initialize
    @cursor = Cursor.new(self)
    super(@cursor)
    @use_midi = true
    @gui = nil

    if $DEBUG
      @debug_file = File.open(DEBUG_FILE, 'a')
    end

    init_data
  end

  def no_gui!
    @no_gui = true
  end

  # Loads +file+. Does its best to restore the current song list, song, and
  # patch after loading.
  def load(file)
    restart = running?
    stop

    @cursor.mark
    init_data
    DSL.new.load(file)
    @loaded_file = file
    @cursor.restore

    if restart
      start(false)
    elsif @cursor.patch
      @cursor.patch.start
    end
  rescue => ex
    raise("error loading #{file}: #{ex}\n" + caller.join("\n"))
  end

  def save(file)
    DSL.new.save(file)
    @loaded_file = file
  rescue => ex
    raise("error saving #{file}: #{ex}" + caller.join("\n"))
  end

  # Initializes the cursor and all data.
  def init_data
    @cursor.clear
    @inputs = []
    @outputs = []
    @song_lists = []
    @all_songs = SortedSongList.new('All Songs')
    @song_lists << @all_songs
    @messages = {}
  end

  # If +init_cursor+ is +true+ (the default), initializes current song list,
  # song, and patch.
  def start(init_cursor = true)
    @cursor.init if init_cursor
    @cursor.patch.start if @cursor.patch
    @running = true
    @inputs.map(&:start)
  end

  # Stop everything, including input instruments' MIDIEye listener threads.
  def stop
    @cursor.patch.stop if @cursor.patch
    @inputs.map(&:stop)
    @running = false
  end

  # Run PatchMaster without the GUI. Don't use this when using PM::Main. If
  # there is a GUI then forward this request to it. Otherwise, call #start,
  # wait for inputs' MIDIEye listener threads to finish, then call #stop.
  # Note that normally nothing stops those threads, so this is used as a way
  # to make sure the script doesn't quit until killed by something like
  # SIGINT.
  def run
    if @gui
      @gui.run
    else
      start(true)
      @inputs.each { |input| input.listener.join }
      stop
    end
  end

  def running?
    @running
  end

  # Send the message with the given +name+ to all outputs. Names are matched
  # case-insensitively.
  def send_message(name)
    msg = @messages[name.downcase]
    if !msg
      message("Message \"#{name}\" not found")
      return
    end

    debug("Sending message \"#{name}\"")
    @outputs.each { |out| out.midi_out(msg) }

    # If the user accidentally calls send_message in a filter at the end,
    # then the filter will return whatever this method returns. Just in
    # case, return nil instead of whatever the preceding code would return.
    nil
  end

  # Sends the +CM_ALL_NOTES_OFF+ controller message to all output
  # instruments on all 16 MIDI channels. If +individual_notes+ is +true+
  # send individual +NOTE_OFF+ messages to all notes as well.
  def panic(individual_notes=false)
    debug("panic(#{individual_notes})")
    @outputs.each do |out|
      MIDI_CHANNELS.times do |chan|
        out.midi_out([CONTROLLER + chan, CM_ALL_NOTES_OFF, 0])
        if individual_notes
          128.times { |note| out.midi_out([NOTE_OFF + chan, note, 0]) }
        end
      end
    end
  end

  # Output +str+ to @debug_file or $stderr.
  def debug(str)
    return unless $DEBUG
    f = @debug_file || $stderr
    f.puts str
    f.flush
  end

  def close_debug_file
    @debug_file.close if @debug_file
  end
end
end
