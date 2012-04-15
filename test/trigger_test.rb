require 'test_helper'

class TriggerTest < PMTest

  def setup
    @pm = PM::PatchMaster.instance
    @pm.load(DSLTest::EXAMPLE_DSL)
    @pm.start
  end

  def teardown
    @pm.stop
    @pm.init_data
  end

  def test_trigger_sends_when_bytes_match
    song = @pm.all_songs.songs.first
    first_patch = song.patches.first
    second_patch = song.patches[1]

    trigger = PM::Trigger.new(:next_patch, [1, 2, 3])
    assert_equal(first_patch, @pm.curr_patch)
    trigger.signal([4, 5, 6])
    assert_equal first_patch, @pm.curr_patch
    trigger.signal([1, 2, 3])
    assert_equal second_patch, @pm.curr_patch
  end
end
