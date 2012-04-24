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

  attr_reader :inputs, :outputs, :all_songs, :song_lists, :no_midi

  # A Cursor to which we delegate incoming position methods (#song_list,
  # #song, #patch, #next_song, #prev_patch, etc.)
  attr_reader :cursor

  def initialize
    @cursor = Cursor.new(self)
    super(@cursor)

    if $DEBUG
      @debug_file = File.open(DEBUG_FILE, 'a')
    end
    @no_midi = false

    init_data
  end

  def no_midi!
    @no_midi = true
  end

  # Loads +file+. Does its best to restore the current song list, song, and
  # patch after loading.
  def load(file)
    restart = running?
    stop

    @cursor.mark
    init_data
    DSL.new(@no_midi).load(file)
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
    DSL.new(@no_midi).save(file)
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

  # Run PatchMaster without the GUI. Don't use this when using PM::Main.
  #
  # Call #start, wait for inputs' MIDIEye listener threads to finish, then
  # call #stop. Note that normally nothing stops those threads, so this is
  # used as a way to make sure the script doesn't quit until killed by
  # something like SIGINT.
  def run
    start(true)
    @inputs.each { |input| input.listener.join }
    stop
  end

  def running?
    @running
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
