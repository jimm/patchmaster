require 'test_helper'

class SortedSongListTest < Test::Unit::TestCase

  def test_sorting
    ssl = PM::SortedSongList.new('')
    %w(c a b).each { |name| ssl << PM::Song.new(name) }
    %w(a b c).each_with_index { |name, i| assert_equal name, ssl.songs[i].name }
  end

  def test_pm_sorting
    ssl = PM::SortedSongList.new('')
    ssl << PM::Song.new("First Song")
    ssl << PM::Song.new("Second Song")
    assert_equal "First Song", ssl.songs[0].name
    assert_equal "Second Song", ssl.songs[1].name
  end
end
