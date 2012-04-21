require 'test_helper'

class DSLTest < Test::Unit::TestCase

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

    assert_kind_of PM::InputInstrument, @pm.inputs[:mb]
    assert_kind_of PM::InputInstrument, @pm.inputs[:ws]
    assert_kind_of PM::OutputInstrument, @pm.outputs[:kz]
    assert_kind_of PM::OutputInstrument, @pm.outputs[:sj]
    assert_equal 'sj', @pm.outputs[:sj].name # name from symbol

    triggers = @pm.inputs[:mb].triggers
    assert_equal 4, triggers.length
    trigger = triggers[0]
    assert_equal [PM::CONTROLLER, PM::CC_GEN_PURPOSE_5, 0], trigger.bytes
    assert_equal "{ prev_song }", @pm.inputs[:mb].triggers[3].text

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

  def test_save
    f = '/tmp/dsl_test_save.rb'
    @dsl.load(EXAMPLE_DSL)
    begin
      @dsl.save(f)
      # TODO write more here
    rescue => ex
      fail ex.to_s
    ensure
      File.delete(f)
    end
  end

  def test_what_saves_is_loadable
    f = '/tmp/dsl_test_what_saves_is_loadable.rb'
    @dsl.load(EXAMPLE_DSL)
    begin
      @dsl.save(f)
      @pm.init_data
      @dsl.load(f)
    rescue => ex
      fail ex.to_s
    ensure
      File.delete(f)
    end
  end

  def test_save_file_contents
    f = '/tmp/dsl_test_save_file_contents.rb'
    @dsl.load(EXAMPLE_DSL)
    @dsl.save('/tmp/dsl_test_save_file_contents.rb')
    str = IO.read(f)
    assert_match 'output 1, :ws, "WaveStation"', str
    assert_match "trigger :mb, [176, 50, 0] { next_patch }", str
    assert_match "trigger :mb, [176, 52, 0] { next_song }", str
    assert_match 'filter { |c, b| b }       # no-op', str
    assert_match 'filter { |c, b| b[0] += 1 }', str
  rescue => ex
    fail ex.to_s
  ensure
    File.delete(f)
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
{ |connection, bytes|
        if bytes.note_off?
          bytes[2] -= 1 unless bytes[2] == 0 # decrease velocity by 1
        end
      }
EOS
    str.strip!
    assert_equal str,
      @pm.all_songs.find('First Song').patches[0].connections[1].filter.text

    assert_equal "{ |c, b| b }       # no-op",
      @pm.all_songs.find('Second Song').patches[0].connections[1].filter.text
  end
end
