require 'test_helper'

class PatchMasterTest < PMTest

  EXAMPLE_DSL = File.join(File.dirname(__FILE__), 'example_dsl.rb')

  def setup
    @pm = PM::PatchMaster.instance
    @pm.load(EXAMPLE_DSL)
    @pm.start

    # We can assume the DSL loader worked properly, since that's tested in
    # DSLTest.
  end

  def teardown
    @pm.stop
    @pm.init_data
  end

  def test_start
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_running
    assert @pm.running?
    assert_only_curr_patch_running
  end

  def test_stop
    @pm.stop
    assert !@pm.curr_patch.running?
    assert !@pm.running?

    @pm.all_songs.songs.each do |song|
      song.patches.each do |patch|
        assert !patch.running?, "patch #{patch.name} should not be running"
      end
    end
  end

  def test_next_song
    @pm.next_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[1], @pm.curr_song
    assert_equal @pm.all_songs.songs[1].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_next_song_end_of_song_list_does_nothing
    @pm.next_song
    @pm.next_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[1], @pm.curr_song
    assert_equal @pm.all_songs.songs[1].patches[0], @pm.curr_patch
    assert @pm.all_songs.songs[1].patches[0].running?
    assert_only_curr_patch_running
  end

  def test_prev_song
    @pm.next_song               # We've proven that next_song works
    @pm.prev_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_prev_song_start_of_song_list_does_nothing
    @pm.prev_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_next_patch
    @pm.next_patch
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[1], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_next_patch_end_of_song
    @pm.next_patch
    @pm.next_patch              # should call next song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[1], @pm.curr_song
    assert_equal @pm.all_songs.songs[1].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_prev_patch
    @pm.next_patch              # We've proven that next_patch works
    @pm.prev_patch
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_prev_patch_start_of_song
    @pm.prev_patch
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_goto_song
    @pm.goto_song('First')
    song = @pm.all_songs.find('First')
    assert_equal song, @pm.curr_song
    assert_equal song.patches.first, @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_goto_song_list
    @pm.goto_song_list('Tonight')
    assert_equal "Tonight's Song List", @pm.curr_song_list.name
    assert_equal @pm.curr_song_list.songs.first, @pm.curr_song
    assert_equal @pm.curr_song_list.songs.first.patches.first, @pm.curr_patch
    assert_only_curr_patch_running
  end

  def test_find_nearest_match
    song = @pm.send(:find_nearest_match, @pm.all_songs.songs, "Frist Song")
    assert_not_nil song
    assert_equal 'First Song', song.name

    song = @pm.send(:find_nearest_match, @pm.all_songs.songs, "Second Song")
    assert_not_nil song
    assert_equal 'Second Song', song.name

    song = @pm.send(:find_nearest_match, @pm.all_songs.songs, "Second Sing")
    assert_not_nil song
    assert_equal 'Second Song', song.name
    assert_only_curr_patch_running
  end

  def test_load_restores_position
    @pm.next_song
    @pm.load(EXAMPLE_DSL)

    assert @pm.running?
    assert_equal 'All Songs', @pm.curr_song_list.name
    assert_equal 'Second Song', @pm.curr_song.name
    assert_equal 'Second Song, First Patch', @pm.curr_patch.name
  end

  def assert_only_curr_patch_running
    @pm.all_songs.songs.each do |song|
      song.patches.each do |patch|
        if patch == @pm.curr_patch
          assert patch.running?, "patch #{patch.name} should be running"
        else
          assert !patch.running?, "patch #{patch.name} should not be running"
        end
      end
    end
  end

end
