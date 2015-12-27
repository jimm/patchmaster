require 'stringio'
require 'test_helper'

class DSLTest < Test::Unit::TestCase

  EXAMPLE_DSL = File.join(File.dirname(__FILE__), 'example_dsl.rb')

  def setup
    @pm = PM::PatchMaster.instance
    @pm.init_data
    @dsl = PM::DSL.new
    @dsl.load(EXAMPLE_DSL)
  end

  def teardown
    @pm.init_data
  end

  def test_load_input
    mb = @pm.inputs.detect { |instr| instr.sym == :mb }
    assert_not_nil mb
    assert_kind_of PM::InputInstrument, mb
  end

  def test_load_output
    kz = @pm.outputs.detect { |instr| instr.sym == :kz }
    assert_kind_of PM::OutputInstrument, kz
  end

  def test_output_name
    sj = @pm.outputs.detect { |instr| instr.sym == :sj }
    assert_kind_of PM::OutputInstrument, sj
    assert_equal 'MockOutputPort 4', sj.name
  end

  def test_load_code_keys
    assert_equal 2, @pm.code_bindings.length
    assert_equal "do\n  $global_code_key_value = 42\nend",
                 @pm.code_bindings.values[0].code_chunk.text
    assert_equal "{ $global_code_key_value = 99 }",
                 @pm.code_bindings.values[1].code_chunk.text
  end

  def test_load_triggers
    mb = @pm.inputs.detect { |instr| instr.sym == :mb }
    triggers = mb.triggers
    assert_equal 5, triggers.length
    trigger = triggers[0]
    assert_equal [PM::CONTROLLER, PM::CC_GEN_PURPOSE_5, 0], trigger.bytes
    assert_equal "{ prev_song }", mb.triggers[3].code_chunk.text
  end

  def test_load_songs
    assert_equal 2, @pm.all_songs.songs.length
    song = @pm.all_songs.find('First Song')
    assert_kind_of PM::Song, song
    assert_kind_of PM::Song, @pm.all_songs.find('Second Song')

    assert_equal 'First Song', song.name
    assert_equal 2, song.patches.length
  end

  def test_load_patches
    song = @pm.all_songs.find('First Song')
    patch = song.patches[0]
    assert_equal [PM::TUNE_REQUEST], patch.start_bytes
    assert_equal [PM::STOP], patch.stop_bytes
    assert_equal 3, patch.connections.length
  end

  def test_load_connection
    mb = @pm.inputs.detect { |instr| instr.sym == :mb }
    kz = @pm.outputs.detect { |instr| instr.sym == :kz }
    song = @pm.all_songs.find('First Song')
    patch = song.patches[0]
    conn = patch.connections[0]

    assert_equal mb, conn.input
    assert_nil conn.input_chan
    assert_equal kz, conn.output
    assert_equal 1, conn.output_chan

    assert_equal 64, conn.pc_prog
    assert_equal (PM::C4..PM::B5), conn.zone
    assert_equal conn.xpose, 12
  end

  def test_load_another_connection
    song = @pm.all_songs.find('First Song')
    patch = song.patches[0]
    conn = patch.connections[1]

    assert_equal 2, conn.bank
    assert_equal 100, conn.pc_prog
  end

  def test_skip_input_chan
    # Make sure that we can skip the second input_chan argument and things
    # are still assigned properly.
    mb = @pm.inputs.detect { |instr| instr.sym == :mb }
    sj = @pm.outputs.detect { |instr| instr.sym == :sj }
    conn = @pm.all_songs.find('Second Song').patches[0].connections[0]

    assert_equal mb, conn.input
    assert_nil conn.input_chan
    assert_equal sj, conn.output
    assert_equal 3, conn.output_chan
  end

  def test_save
    f = '/tmp/dsl_test_save.rb'
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
    @dsl.save('/tmp/dsl_test_save_file_contents.rb')
    str = IO.read(f)
    assert_match 'output 1, :ws_out, "WaveStation"', str
    assert_match "message \"Tune Request\", [#{PM::TUNE_REQUEST}]", str
    assert_match 'message_key :f1, "Tune Request"', str
    assert_match "trigger :mb, [176, 50, 0] { next_patch }", str
    assert_match "trigger :mb, [176, 52, 0] { next_song }", str
    assert_match 'filter { |c, b| b }       # no-op', str
    assert_match 'filter { |c, b| b[0] += 1; b }', str
  rescue => ex
    fail ex.to_s
  ensure
    File.delete(f)
  end

  def test_aliases
    conn = @pm.all_songs.find('Second Song').patches[0].connections[0]
    assert_equal 22, conn.pc_prog
    assert_not_nil conn.zone
  end

  def test_zone_takes_empty_end
    conn = @pm.all_songs.find('Second Song').patches[0].connections[0]
    assert_equal (PM::D4..127), conn.zone
  end

  def test_zone_takes_range
    conn = @pm.all_songs.find('Second Song').patches[0].connections[1]
    assert_equal (PM::C4..PM::B5), conn.zone
  end

  def test_unique_instrument_symbol
    file = '/tmp/dsl_test.rb'
    str = IO.read(EXAMPLE_DSL)
    str.gsub!(/output 4, :sj/, 'output 4, :ws_out')
    File.open(file, 'w') { |f| f.puts str }
    begin
      @pm.init_data
      @dsl = PM::DSL.new
      @dsl.load(file)
      fail "expected unique symbol error to be raised"
    rescue => ex
      assert_match /can not have the same symbol \(:ws_out\)/, ex.to_s
    ensure
      File.delete(file)
    end
  end

  def test_read_filter_text
    str = <<EOS
{ |connection, bytes|
        if bytes.note_off?
          bytes[2] -= 1 unless bytes[2] == 0 # decrease velocity by 1
        end
        bytes
      }
EOS
    str.strip!
    assert_equal str,
                 @pm.all_songs
                   .find('First Song')
                   .patches[0]
                   .connections[1]
                   .filter
                   .code_chunk
                   .text

    assert_equal "{ |c, b| b }       # no-op",
                 @pm.all_songs
                   .find('Second Song')
                   .patches[0]
                   .connections[1]
                   .filter
                   .code_chunk
                   .text
  end

  def test_messages
    assert_equal ["Tune Request", [PM::TUNE_REQUEST]],
                 @pm.messages["Tune Request".downcase]
  end
end
