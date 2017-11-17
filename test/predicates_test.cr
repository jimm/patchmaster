require 'test_helper'

# Not gonna test everything exhaustively.
class PredicatesTest < Test::Unit::TestCase

  include PM

  def test_high_nibble
    assert_equal NOTE_ON, (NOTE_ON + 4).high_nibble
  end

  def test_channel
    assert_equal 5, (NOTE_OFF + 5).channel
  end

  def test_channel_p
    assert NOTE_ON.channel?
    assert (POLY_PRESSURE + 15).channel?
    assert (CONTROLLER + 3).channel?
    assert !SYSEX.channel?
  end

  def test_note_p
    assert NOTE_ON.note?
    assert (POLY_PRESSURE + 10).note?
    assert !CONTROLLER.note?
  end

  def test_realtime
    assert !0xf0.realtime?
    assert 0xf8.realtime?
    assert !0x100.realtime?
  end

  def test_array_high_nibble
    assert_equal NOTE_ON, [(NOTE_ON + 4), 34, 12].high_nibble
  end

  def test_array_channel
    assert_equal 5, [(NOTE_OFF + 5), 34, 12].channel
  end

  def test_array_channel_p
    assert [NOTE_ON + 3, 4, 5].channel?
    assert [(POLY_PRESSURE + 15), 0xfe].channel?
    assert ![SYSEX, 1, 2, 3, 4].channel?
  end

  def test_array_realtime
    assert ![0xf0, 1, 2, 3].realtime?
    assert [0xf8].realtime?
    assert ![0x100, 1, 2, 3].realtime?
  end

end
