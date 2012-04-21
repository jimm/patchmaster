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
    DSL.new(@no_midi).save(file)
    @loaded_file = file
  rescue => ex
    raise("error saving #{file}: #{ex}" + caller.join("\n"))
  end

  # Initializes the cursor and all data.
  def init_data
    @cursor.clear
    @inputs = {}
    @outputs = {}
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
  end

  def stop
    @cursor.patch.stop if @cursor.patch
    @running = false
  end

  def running?
    @running
  end

  # Sends the +CM_ALL_NOTES_OFF+ controller message to all output
  # instruments on all 16 MIDI channels. If +individual_notes+ is +true+
  # send individual +NOTE_OFF+ messages to all notes as well.
  def panic(individual_notes=false)
    debug("panic(#{individual_notes})")
    @outputs.values.each do |out|
      MIDI_CHANNELS.times do |chan|
        out.midi_out([CONTROLLER + chan, CM_ALL_NOTES_OFF, 0])
        if individual_notes
          128.times { |note| out.midi_out([NOTE_OFF + chan, note, 0]) }
        end
      end
    end
  end

  # Opens the most recently loaded/saved file name in an editor. After
  # editing, the file is re-loaded.
  def edit
    editor_command = find_editor
    unless editor_command
      message("Can not find $VISUAL, $EDITOR, vim, or vi on your path")
      return
    end

    cmd = "#{editor_command} #{@loaded_file}"
    debug(cmd)
    system(cmd)
    load(@loaded_file)
  end

  # Return the first legit command from $VISUAL, $EDITOR, vim, vi, and
  # notepad.exe.
  def find_editor
    @editor ||= [ENV['VISUAL'], ENV['EDITOR'], 'vim', 'vi', 'notepad.exe'].compact.detect do |cmd|
      system('which', cmd) || File.exist?(cmd)
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
