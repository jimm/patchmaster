require 'test_helper'

class DSLTest < PMTest

  EXAMPLE_DSL = File.join(File.dirname(__FILE__), 'example_dsl.rb')

  def setup
    @pm = PM::PatchMaster.instance
    @pm.init_data
    @dsl = PM::DSL.new(true)    # no MIDI (ignore errors, no-op ports)
  end

  def teardown
    @pm.init_data
  end

  def test_load
    @dsl.load(EXAMPLE_DSL)

    assert_kind_of PM::InputDevice, @pm.inputs[:mb]
    assert_kind_of PM::InputDevice, @pm.inputs[:ws]
    assert_kind_of PM::OutputDevice, @pm.outputs[:kz]
    assert_kind_of PM::OutputDevice, @pm.outputs[:sj]
    assert_equal 'sj', @pm.outputs[:sj].name # name from symbol

    assert_equal 2, @pm.all_songs.songs.length
    song = @pm.all_songs.find('First Song')
    assert_kind_of PM::Song, song
    assert_kind_of PM::Song, @pm.all_songs.find('Second Song')

    assert_equal 'First Song', song.name
    assert_equal 2, song.patches.length

    patch = song.patches[0]
    assert_equal [PM::TUNE_REQUEST], patch.start_bytes
    assert_equal 3, patch.connections.length

    conn = patch.connections[0]

    assert_equal @pm.inputs[:mb], conn.input
    assert_nil conn.input_chan
    assert_equal @pm.outputs[:kz], conn.output
    assert_equal 1, conn.output_chan

    assert_equal 64, conn.pc_prog
    assert_equal (PM::C4..PM::B5), conn.zone
    assert_equal conn.xpose, 12
  end

  def test_aliases
    @dsl.load(EXAMPLE_DSL)
    conn = @pm.all_songs.find('Second Song').patches[0].connections[0]
    assert_equal 22, conn.pc_prog
    assert_not_nil conn.zone
  end

  def test_zone_takes_empty_end
    @dsl.load(EXAMPLE_DSL)
    conn = @pm.all_songs.find('Second Song').patches[0].connections[0]
    assert_equal (PM::D4..127), conn.zone
  end

  def test_zone_takes_range
    @dsl.load(EXAMPLE_DSL)
    conn = @pm.all_songs.find('Second Song').patches[0].connections[1]
    assert_equal (PM::C4..PM::B5), conn.zone
  end

  def test_read_filter_text
    @dsl.load(EXAMPLE_DSL)
    str = <<EOS
{ |device, bytes|
        if bytes.note_off?
          bytes[2] -= 1 unless bytes[2] == 0 # decrease velocity by 1
        end
      }
EOS
    assert_equal str,
      @pm.all_songs.find('First Song').patches[0].connections[1].filter.text

    assert_equal "{ |d, b| b }       # no-op\n",
      @pm.all_songs.find('Second Song').patches[0].connections[1].filter.text
  end
end
