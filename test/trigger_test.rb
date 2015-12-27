require 'test_helper'

class TriggerTest < Test::Unit::TestCase

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

    x = 0
    trigger = PM::Trigger.new([1, 2, 3], PM::CodeChunk.new(Proc.new { x += 1 }))

    trigger.signal([4, 5, 6])
    assert_equal 0, x

    trigger.signal([1, 2, 3])
    assert_equal 1, x

    trigger.signal([1, 2, 3])
    assert_equal 2, x
  end
end
