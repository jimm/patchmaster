module PM

# A PM::Cursor knows the current PM::SongList, PM::Song, and PM::Patch, how
# to move between songs and patches, and how to find them given name
# regexes. A Cursor does not start/stop patches or manage connections.
class Cursor

  attr_reader :song_list, :song, :patch

  def initialize(pm)
    @pm = pm
    clear
  end

  # Set @song_list, @song, and @patch to +nil+.
  def clear
    @song_list = @song = @patch = nil
    # Do not erase names saved by #mark.
  end

  # Set @song_list to All Songs, @song to first song, and
  # @patch to song's first patch. Song and patch may be +nil+.
  def init
    @song_list = @pm.song_lists.first
    @song = @song_list.songs.first
    if @song
      @patch = @song.patches.first
    else
      @patch = nil
    end
  end

  def next_song
    return unless @song_list
    return if @song_list.songs.last == @song

    @patch.stop if @patch
    @song = @song_list.songs[@song_list.songs.index(@song) + 1]
    @patch = @song.patches.first
    @patch.start
  end

  def prev_song
    return unless @song_list
    return if @song_list.songs.first == @song

    @patch.stop if @patch
    @song = @song_list.songs[@song_list.songs.index(@song) - 1]
    @patch = @song.patches.first
    @patch.start
  end

  def next_patch
    return unless @song
    if @song.patches.last == @patch
      next_song
    elsif @patch
      @patch.stop
      @patch = @song.patches[@song.patches.index(@patch) + 1]
      @patch.start
    end
  end

  def prev_patch
    return unless @song
    if @song.patches.first == @patch
      prev_song
    elsif @patch
      @patch.stop
      @patch = @song.patches[@song.patches.index(@patch) - 1]
      @patch.start
    end
  end

  def goto_song(name_regex)
    new_song_list = new_song = new_patch = nil
    new_song = @song_list.find(name_regex) if @song_list
    new_song = @@pm.all_songs.find(name_regex) unless new_song
    new_patch = new_song ? new_song.patches.first : nil

    if (new_song && new_song != @song) || # moved to new song
        (new_song == @song && @patch != new_patch) # same song but not at same first patch

      @patch.stop if @patch

      if @song_list.songs.include?(new_song)
        new_song_list = @song_list
      else
        # Not found in current song list. Switch to @pm.all_songs list.
        new_song_list = @@pm.all_songs
      end

      @song_list = new_song_list
      @song = new_song
      @patch = new_patch
      @patch.start
    end
  end

  def goto_song_list(name_regex)
    name_regex = Regexp.new(name_regex.to_s, true) # make case-insensitive
    new_song_list = @pm.song_lists.detect { |song_list| song_list.name =~ name_regex }
    return unless new_song_list

    @song_list = new_song_list

    new_song = @song_list.songs.first
    new_patch = new_song ? new_song.patches.first : nil

    if new_patch != @patch
      @patch.stop if @patch
      new_patch.start if new_patch
    end
    @song = new_song
    @patch = new_patch
  end

  # Remembers the names of the current song list, song, and patch.
  # Used by #restore.
  def mark
    @song_list_name = @song_list ? @song_list.name : nil
    @song_name = @song ? @song.name : nil
    @patch_name = @patch ? @patch.name : nil
  end

  # Using the names saved by #save, try to find them now.
  #
  # Since names can change we use Damerau-Levenshtein distance on lowercase
  # versions of all strings.
  def restore
    return unless @song_list_name   # will be nil on initial load

    @song_list = find_nearest_match(@pm.song_lists, @song_list_name) || @pm.all_songs
    @song = find_nearest_match(@song_list.songs, @song_name) || @song_list.songs.first
    if @song
      @patch = find_nearest_match(@song.patches, @patch_name) || @song.patches.first
    else
      @patch = nil
    end
  end

  # List must contain objects that respond to #name. If +str+ is nil or
  # +list+ is +nil+ or empty then +nil+ is returned.
  def find_nearest_match(list, str)
    return nil unless str && list && !list.empty?

    str = str.downcase
    distances = list.collect { |item| dameraulevenshtein(str, item.name.downcase) }
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
