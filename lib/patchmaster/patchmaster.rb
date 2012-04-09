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
class PatchMaster

  include Singleton

  attr_reader :inputs, :outputs, :all_songs, :song_lists, :no_midi
  attr_reader :curr_song_list, :curr_song, :curr_patch

  def initialize
    init_data
    @no_midi = false
    @curr_song_list = @curr_song = @curr_patch = nil
  end

  def no_midi!
    @no_midi = true
  end

  def load(file)
    stop
    init_data
    DSL.new(@no_midi).load(file)
  rescue => ex
    raise("error loading #{file}: #{ex}\n" + caller.join("\n"))
  end

  def save(file)
    DSL.new(@no_midi).save(file)
    message("saved #{file}")
  rescue => ex
    raise("error saving #{file}: #{ex}")
  end

  def init_data
    @curr_song_list = @curr_song = @curr_patch = nil
    @inputs = {}
    @outputs = {}
    @song_lists = List.new
    @all_songs = SortedSongList.new('All Songs')
    @song_lists << @all_songs
  end

  def start
    @curr_song_list = @song_lists.first # sets cursor in @song_lists
    @curr_song = @curr_song_list.first_song
    if @curr_song
      @curr_patch = @curr_song.first_patch
      @curr_patch.start
    else
      @curr_patch = nil
    end
  end

  def stop
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

end
end
