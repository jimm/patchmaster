# frozen_string_literal: true

module PM
  class SortedSongList < SongList
    def <<(song)
      next_song_after = @songs.detect { |s| s.name > song.name }
      if next_song_after
        @songs.insert(@songs.index(next_song_after), song)
      else
        super(song)
      end
    end
  end
end
