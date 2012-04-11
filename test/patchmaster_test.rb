require 'test_helper'

class PatchMasterTest < PMTest

  def setup
    @pm = PM::PatchMaster.instance
    @pm.load(DSLTest::EXAMPLE_DSL)
    @pm.start

    # We can assume the DSL loader worked properly, since that's tested in
    # DSLTest.
  end

  def teardown
    assert_only_curr_patch_running

    @pm.stop
    @pm.init_data
  end

  def test_start
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
  end

  def test_running
    assert @pm.instance_variable_get(:@running)
  end

  def test_stop
    @pm.stop
    assert_nil @pm.curr_patch
    assert !@pm.instance_variable_get(:@running)
  end

  def test_next_song
    @pm.next_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[1], @pm.curr_song
    assert_equal @pm.all_songs.songs[1].patches[0], @pm.curr_patch
  end

  def test_next_song_end_of_song_list_does_nothing
    @pm.next_song
    @pm.next_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[1], @pm.curr_song
    assert_equal @pm.all_songs.songs[1].patches[0], @pm.curr_patch
    assert @pm.all_songs.songs[1].patches[0].running?
  end

  def test_prev_song
    @pm.next_song               # We've proven that next_song works
    @pm.prev_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
  end

  def test_prev_song_start_of_song_list_does_nothing
    @pm.prev_song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
  end

  def test_next_patch
    @pm.next_patch
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[1], @pm.curr_patch
  end

  def test_next_patch_end_of_song
    @pm.next_patch
    @pm.next_patch              # should call next song
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[1], @pm.curr_song
    assert_equal @pm.all_songs.songs[1].patches[0], @pm.curr_patch
  end

  def test_prev_patch
    @pm.next_patch              # We've proven that next_patch works
    @pm.prev_patch
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
  end

  def test_prev_patch_start_of_song
    @pm.prev_patch
    assert_equal @pm.all_songs, @pm.curr_song_list
    assert_equal @pm.all_songs.songs[0], @pm.curr_song
    assert_equal @pm.all_songs.songs[0].patches[0], @pm.curr_patch
  end

  def test_goto_song
    @pm.goto_song('First')
    song = @pm.all_songs.find('First')
    assert_equal song, @pm.curr_song
    assert_equal song.curr_patch, @pm.curr_patch
  end

  def test_goto_song_list
    @pm.goto_song_list('Tonight')
    assert_equal "Tonight's Song List", @pm.curr_song_list.name
    assert_equal @pm.curr_song_list.first_song, @pm.curr_song
    assert_equal @pm.curr_song_list.first_song.first_patch, @pm.curr_patch
  end

  def test_find_nearest_match
    song = @pm.find_nearest_match(@pm.all_songs.songs, "Frist Song")
    assert_not_nil song
    assert_equal 'First Song', song.name

    song = @pm.find_nearest_match(@pm.all_songs.songs, "Second Song")
    assert_not_nil song
    assert_equal 'Second Song', song.name

    song = @pm.find_nearest_match(@pm.all_songs.songs, "Second Sing")
    assert_not_nil song
    assert_equal 'Second Song', song.name
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
