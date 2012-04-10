require 'test_helper'

class SongListTest < PMTest

  def setup
    @song_info = []
    @song_list = PM::SongList.new('Song List')
    2.times { |i|
      @song_info << create_song(i)
      @song_list << @song_info.last[:song]
    }
  end

  def test_find
    s = @song_info[1][:song]
    assert_equal s, @song_list.find('Untitled 1')
    assert_equal s, @song_list.find('untitled 1')
    assert_equal s, @song_list.find('1')
  end

  def create_song(n)
    song = PM::Song.new("Untitled #{n}")
    patch_info = []
    2.times do |i|
      patch_info << create_patch(i)
      song << patch_info.last[:patch]
    end
    {
      :patch_info => patch_info,
      :song => song
    }
  end

  def create_patch(n)
    in_instrument = PM::InputInstrument.new("test_in #{n}", 0, true)
    out_instrument = PM::OutputInstrument.new("test_out #{n}", 0, true)
    options = {:pc_prog => n, :zone => (40..60), :xpose => 12}
    conn = PM::Connection.new(in_instrument, nil, out_instrument, 2, nil, options)
    patch = PM::Patch.new("Untitled #{n}")
    patch << conn
    {
      :in => in_instrument,
      :out => out_instrument,
      :patch => patch,
      :connection => conn
    }
  end

end
