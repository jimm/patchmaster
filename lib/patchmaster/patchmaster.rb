require 'singleton'
require 'patchmaster/sorted_song_list'

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
#
# A stopped PatchMaster instance can't be restarted. That's mostly because
# triggers are erased instead of disabled; it wouldn't be too hard
class PatchMaster

  DEBUG_FILE = '/tmp/pm_debug.txt'

  include Singleton

  attr_reader :inputs, :outputs, :all_songs, :song_lists, :no_midi
  attr_reader :curr_song_list, :curr_song, :curr_patch
  attr_reader :debug_file

  def initialize
    if $DEBUG
      @debug_file = File.open(DEBUG_FILE, 'a')
    end
    init_data
    @no_midi = false
    @curr_song_list = @curr_song = @curr_patch = nil
  end

  def no_midi!
    @no_midi = true
  end

  # Stops everything and loads +file+. Does its best to restore the current
  # song list, song, and patch.
  def load(file)
    curr_pos = curr_position()
    stop
    init_data
    DSL.new(@no_midi).load(file)
    @loaded_file = file
    restore_position(curr_pos)
    @curr_patch.start if @curr_patch
  rescue => ex
    raise("error loading #{file}: #{ex}\n" + caller.join("\n"))
  end

  def save(file)
    DSL.new(@no_midi).save(file)
    message("saved #{file}")
  rescue => ex
    raise("error saving #{file}: #{ex}" + caller.join("\n"))
  end

  # Initializes the cursor and all data.
  def init_data
    @curr_song_list = @curr_song = @curr_patch = nil
    @inputs = {}
    @outputs = {}
    @song_lists = List.new
    @all_songs = SortedSongList.new('All Songs')
    @song_lists << @all_songs
  end

  # If +init_cursor+ is +true+ (the default), initializes current song list,
  # song, and patch. Starts a new thread that listens for MIDI input and
  # processes it.
  def start(init_cursor = true)
    if init_cursor
      @curr_song_list = @song_lists.first # sets cursor in @song_lists
      @curr_song = @curr_song_list.first_song
      if @curr_song
        @curr_patch = @curr_song.first_patch
      else
        @curr_patch = nil
      end
    end
    @curr_patch.start if @curr_patch

    @running = true
    Thread.new do
      loop do
        break unless @running
        @inputs.values.map(&:gets_data)
      end
    end
  end

  # Stops the MIDI input thread and sets the cursor to +nil+.
  def stop
    @running = false
    @curr_patch.stop if @curr_patch
    @curr_song_list = @curr_song = @curr_patch = nil
  end

  def next_song
    return unless @curr_song_list
    return if @curr_song_list.last_song?

    @curr_patch.stop if @curr_patch
    @curr_song = @curr_song_list.next_song
    @curr_patch = @curr_song.first_patch
    @curr_patch.start
  end

  def prev_song
    return unless @curr_song_list
    return if @curr_song_list.first_song?

    @curr_patch.stop if @curr_patch
    @curr_song = @curr_song_list.prev_song
    @curr_patch = @curr_song.first_patch
    @curr_patch.start
  end

  def next_patch
    return unless @curr_song
    if @curr_song.last_patch?
      next_song
    elsif @curr_patch
      @curr_patch.stop
      @curr_patch = @curr_song.next_patch
      @curr_patch.start
    end
  end

  def prev_patch
    return unless @curr_song
    if @curr_song.first_patch?
      prev_song
    elsif @curr_patch
      @curr_patch.stop
      @curr_patch = @curr_song.prev_patch
      @curr_patch.start
    end
  end

  def goto_song(name_regex)
    new_song_list = new_song = new_patch = nil
    new_song = @curr_song_list.find(name_regex) if @curr_song_list
    new_song = @all_songs.find(name_regex) unless new_song
    new_patch = new_song ? new_song.first_patch : nil

    if (new_song && new_song != @curr_song) || # moved to new song
        (new_song == @curr_song && @curr_patch != new_patch) # same song but not at same first patch

      @curr_patch.stop if @curr_patch

      if @curr_song_list.songs.include?(new_song)
        new_song_list = @curr_song_list
      else
        # Not found in current song list. Switch to all_songs list.
        new_song_list = @all_songs
      end
      new_song_list.curr_song = new_song # move to that song in selected song list

      @curr_song_list = new_song_list
      @curr_song = new_song
      @curr_patch = new_patch
      @curr_patch.start
    end
  end

  def goto_song_list(name_regex)
    name_regex = Regexp.new(name_regex.to_s, true) # make case-insensitive
    new_song_list = @song_lists.detect { |song_list| song_list.name =~ name_regex }
    return unless new_song_list

    @curr_song_list = new_song_list
    @song_lists.curr = new_song_list # set cursor

    new_song = @curr_song_list.first_song
    new_patch = new_song ? new_song.first_patch : nil

    if new_patch != @curr_patch
      @curr_patch.stop if @curr_patch
      new_patch.start if new_patch
    end
    @curr_song = new_song
    @curr_patch = new_patch
  end

  def panic
    @outputs.values.each do |out|
      MIDI_CHANNELS.times do |chan|
        out.midi_out([CONTROLLER + chan, CM_ALL_NOTES_OFF, 0])
      end
    end
  end

  def edit
    cmd = "#{ENV['VISUAL'] || ENV['EDITOR'] || 'vi'} #{@loaded_file}"
    message(cmd) if $DEBUG
    system(cmd)
    load(@loaded_file)
  end

  def debug(str)
    if $DEBUG
      if @debug_file
        @debug_file.puts str
        @debug_file.flush
      else
        $stderr.puts str
      end
    end
  end

  def close_debug_file
    @debug_file.close if @debug_file
  end

  # ****************************************************************

  private

  # Returns an array of names of the current song list, song, and patch.
  # Used by #restore_position.
  def curr_position
    [@curr_song_list ? @curr_song_list.name : nil,
     @curr_song ? @curr_song.name : nil,
     @curr_patch ? @curr_patch.name : nil]
  end

  # Given names of a song list, song, and patch, try to find them now.
  #
  # Since names can change we use Damerau-Levenshtein distance on lowercase
  # versions of all strings.
  def restore_position(curr_pos)
    return unless curr_pos[0]   # will be nil on initial load

    song_list_name, song_name, patch_name = curr_pos

    @curr_song_list = find_nearest_match(@song_lists, song_list_name) || @all_songs
    @song_lists.curr = @curr_song_list

    @curr_song = find_nearest_match(@curr_song_list.songs, song_name) || @curr_song_list.first_song
    if @curr_song
      @curr_song_list.curr_song = @curr_song
      @curr_patch = find_nearest_match(@curr_song.patches, patch_name) || @curr_song.first_patch
      @curr_song.curr_patch = @curr_patch if @curr_song
    end
  end

  # List must contain objects that respond to #name. If +str+ is nil or
  # +list+ is +nil+ or empty then +nil+ is returned.
  def find_nearest_match(list, str)
    return nil unless str && list && !list.empty?

    distances = list.collect { |item| dameraulevenshtein(str, item.name) }
    min_distance = distances.min
    list[distances.index(distances.min)]
  end

  # https://gist.github.com/182759 (git://gist.github.com/182759.git)
  # Referenced from http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
  def dameraulevenshtein(seq1, seq2)
    oneago = nil
    thisrow = (1..seq2.size).to_a + [0]
    seq1.size.times do |x|
      twoago, oneago, thisrow = oneago, thisrow, [0] * seq2.size + [x + 1]
      seq2.size.times do |y|
        delcost = oneago[y] + 1
        addcost = thisrow[y - 1] + 1
        subcost = oneago[y - 1] + ((seq1[x] != seq2[y]) ? 1 : 0)
        thisrow[y] = [delcost, addcost, subcost].min
        if (x > 0 and y > 0 and seq1[x] == seq2[y-1] and seq1[x-1] == seq2[y] and seq1[x] != seq2[y])
          thisrow[y] = [thisrow[y], twoago[y-2] + 1].min
        end
      end
    end
    return thisrow[seq2.size - 1]
  end
end
end
