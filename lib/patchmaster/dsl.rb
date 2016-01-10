require 'unimidi'
require_relative './code_chunk'

module PM

# Implements a DSL for describing a PatchMaster setup.
class DSL

  include PM

  def initialize
    @pm = PatchMaster.instance
    init
  end

  # Initialize state used for reading.
  def init
    @inputs = {}
    @outputs = {}
    @triggers = []
    @filters = []
    @code_keys = []
    @songs = {}                 # key = name, value = song
  end

  def load(file)
    contents = IO.read(file)
    init
    instance_eval(contents)
    read_code_keys(contents)
    read_triggers(contents)
    read_filters(contents)
  end

  def input(port_num, sym, name=nil)
    raise "input: two inputs can not have the same symbol (:#{sym})" if @inputs[sym]

    input = InputInstrument.new(sym, name, port_num, @pm.use_midi?)
    @inputs[sym] = input
    @pm.inputs << input
  rescue => ex
    raise "input: error creating input instrument \"#{name || sym}\" on input port #{port_num}: #{ex}"
  end
  alias_method :inp, :input

  def output(port_num, sym, name=nil)
    raise "output: two outputs can not have the same symbol (:#{sym})" if @outputs[sym]

    output = OutputInstrument.new(sym, name, port_num, @pm.use_midi?)
    @outputs[sym] = output
    @pm.outputs << output
  rescue => ex
    raise "output: error creating output instrument \"#{name || sym}\" on output port #{port_num}: #{ex}"
  end
  alias_method :out, :output
  alias_method :outp, :output

  def message(name, bytes)
    @pm.messages[name.downcase] = [name, bytes]
  end

  def message_key(key_or_sym, name)
    if name.is_a?(Symbol)
        name, key_or_sym = key_or_sym, name
        $stderr.puts "WARNING: the arguments to message_key are now key first, then name."
        $stderr.puts "I will use #{name} as the name and #{key_or_sym} as the key for now."
        $stderr.puts "Please swap them for future compatability."
    end
    if key_or_sym.is_a?(String) && name.is_a?(String)
      if name.length == 1 && key_or_sym.length > 1
        name, key_or_sym = key_or_sym, name
        $stderr.puts "WARNING: the arguments to message_key are now key first, then name."
        $stderr.puts "I will use #{name} as the name and #{key_or_sym} as the key for now."
        $stderr.puts "Please swap them for future compatability."
      elsif name.length == 1 && key_or_sym.length == 1
        raise "message_key: since both name and key are one-character strings, I can't tell which is which. Please make the name longer."
      end
    end
    @pm.bind_message(name, to_binding_key(key_or_sym))
  end

  def code_key(key_or_sym, &block)
    ck = CodeKey.new(to_binding_key(key_or_sym), CodeChunk.new(block))
    @pm.bind_code(ck)
    @code_keys << ck
  end

  def trigger(instrument_sym, bytes, &block)
    instrument = @inputs[instrument_sym]
    raise "trigger: error finding instrument #{instrument_sym}" unless instrument
    t = Trigger.new(bytes, CodeChunk.new(block))
    instrument.triggers << t
    @triggers << t
  end

  def song(name)
    @song = Song.new(name)      # ctor saves into @pm.all_songs
    @songs[name] = @song
    yield @song if block_given?
  end

  def notes(txt)
    @song.notes = txt
  end

  def patch(name)
    @patch = Patch.new(name)
    @song << @patch
    yield @patch if block_given?
  end

  def start_bytes(bytes)
    @patch.start_bytes = bytes
  end

  def stop_bytes(bytes)
    @patch.stop_bytes = bytes
  end

  # in_chan can be skipped, so "connection :foo, :bar, 1" is the same as
  # "connection :foo, nil, :bar, 1".
  def connection(in_sym, in_chan, out_sym, out_chan=nil)
    input = @inputs[in_sym]
    if in_chan.kind_of? Symbol
      out_chan = out_sym
      out_sym = in_chan
      in_chan = nil
    end
    raise "can't find input instrument #{in_sym}" unless input
    output = @outputs[out_sym]
    raise "can't find outputput instrument #{out_sym}" unless output

    @conn = Connection.new(input, in_chan, output, out_chan)
    @patch << @conn
    yield @conn if block_given?
  end
  alias_method :conn, :connection
  alias_method :c, :connection

  # One byte: program change
  # Two bytes: bank lsb, program change
  # Three bytes: bank msb, bank lsb, program change
  def prog_chg(bank_msb, bank_lsb=nil, prog=nil)
    if prog
      @conn.bank_msb = bank_msb
      @conn.bank_lsb = bank_lsb
      @conn.pc_prog = prog
    elsif bank_lsb
      @conn.bank_lsb = bank_msb
      @conn.pc_prog = bank_lsb
    else
      @conn.pc_prog = bank_msb
    end
  end
  alias_method :pc, :prog_chg

  # If +start_or_range+ is a Range, use that. Else either or both params may
  # be nil.
  def zone(start_or_range=nil, stop=nil)
    @conn.zone = if start_or_range.kind_of? Range
                         start_or_range
                       elsif start_or_range == nil && stop == nil
                         nil
                       else
                         ((start_or_range || 0) .. (stop || 127))
                       end
  end
  alias_method :z, :zone

  def transpose(xpose)
    @conn.xpose = xpose
  end
  alias_method :xpose, :transpose
  alias_method :x, :transpose

  def filter(&block)
    @conn.filter = Filter.new(CodeChunk.new(block))
    @filters << @conn.filter
  end
  alias_method :f, :filter

  def song_list(name, song_names)
    sl = SongList.new(name)
    @pm.song_lists << sl
    song_names.each do |sn|
      song = @songs[sn]
      raise "song \"#{sn}\" not found (song list \"#{name}\")" unless song
      sl << song
    end
  end

  def alias_input(new_sym, old_sym)
    @inputs[new_sym] = @inputs[old_sym]
  end

  def alias_output(new_sym, old_sym)
    @outputs[new_sym] = @outputs[old_sym]
  end

  # ****************************************************************

  def save(file)
    File.open(file, 'w') { |f|
      save_instruments(f)
      save_messages(f)
      save_message_keys(f)
      save_code_keys(f)
      save_triggers(f)
      save_songs(f)
      save_song_lists(f)
    }
  end

  def save_instruments(f)
    @pm.inputs.each do |instr|
      f.puts "input #{instr.port_num}, :#{instr.sym}, #{instr.name.inspect}"
    end
    @pm.outputs.each do |instr|
      f.puts "output #{instr.port_num}, :#{instr.sym}, #{instr.name.inspect}"
    end
    f.puts
  end

  def save_messages(f)
    @pm.messages.each do |_, (correct_case_name, msg)|
      f.puts "message #{correct_case_name.inspect}, #{msg.inspect}"
    end
  end

  def save_message_keys(f)
    @pm.message_bindings.each do |key, message_name|
      f.puts "message_key #{to_save_key(key).inspect}, #{message_name.inspect}"
    end
  end

  def save_code_keys(f)
    @pm.code_bindings.values.each do |code_key|
      str = if code_key.code_chunk.text[0] == '{'
              "code_key(#{to_save_key(code_key.key).inspect}) #{code_key.code_chunk.text}"
            else
              "code_key #{to_save_key(code_key.key).inspect} #{code_key.code_chunk.text}"
            end
      f.puts str
    end
  end

  def save_triggers(f)
    @pm.inputs.each do |instrument|
      instrument.triggers.each do |trigger|
        str = "trigger :#{instrument.sym}, #{trigger.bytes.inspect} #{trigger.code_chunk.text}"
        f.puts str
      end
    end
    f.puts
  end

  def save_songs(f)
    @pm.all_songs.songs.each do |song|
      f.puts "song #{song.name.inspect} do"
      song.patches.each { |patch| save_patch(f, patch) }
      f.puts "end"
      f.puts
    end
  end

  def save_patch(f, patch)
    f.puts "  patch #{patch.name.inspect} do"
    f.puts "    start_bytes #{patch.start_bytes.inspect}" if patch.start_bytes
    patch.connections.each { |conn| save_connection(f, conn) }
    f.puts "  end"
  end

  def save_connection(f, conn)
    in_chan = conn.input_chan ? conn.input_chan + 1 : 'nil'
    out_chan = conn.output_chan + 1
    f.puts "    conn :#{conn.input.sym}, #{in_chan}, :#{conn.output.sym}, #{out_chan} do"
    f.puts "      prog_chg #{conn.pc_prog}" if conn.pc?
    f.puts "      zone #{conn.note_num_to_name(conn.zone.begin)}, #{conn.note_num_to_name(conn.zone.end)}" if conn.zone
    f.puts "      xpose #{conn.xpose}" if conn.xpose
    f.puts "      filter #{conn.filter.code_chunk.text}" if conn.filter
    f.puts "    end"
  end

  def save_song_lists(f)
    @pm.song_lists.each do |sl|
      next if sl == @pm.all_songs
      f.puts "song_list #{sl.name.inspect}, ["
      @pm.all_songs.songs.each do |song|
        f.puts "  #{song.name.inspect},"
      end
      f.puts "]"
    end
  end

  # ****************************************************************

  private

  # Translate symbol like :f1 to the proper function key value.
  def to_binding_key(key_or_sym)
    if key_or_sym.is_a?(Symbol) && PM::Main::FUNCTION_KEY_SYMBOLS[key_or_sym]
      key_or_sym = PM::Main::FUNCTION_KEY_SYMBOLS[key_or_sym]
    end
  end

  # Translate function key values into symbol strings and other keys into
  # double-quoted strings.
  def to_save_key(key)
    if PM::Main::FUNCTION_KEY_SYMBOLS.value?(key)
      PM::Main::FUNCTION_KEY_SYMBOLS.key(key)
    else
      key
    end
  end

  def read_triggers(contents)
    read_block_text('trigger', @triggers, contents)
  end

  def read_filters(contents)
    read_block_text('filter', @filters, contents)
  end

  def read_code_keys(contents)
    read_block_text('code_key', @code_keys, contents)
  end

  # Extremely simple block text reader. Relies on indentation to detect end
  # of code block.
  def read_block_text(name, containers, contents)
    i = -1
    in_block = false
    block_indentation = nil
    block_end_token = nil
    chunk = nil
    contents.each_line do |line|
      if line =~ /^(\s*)#{name}\s*.*?(({|do|->\s*{|lambda\s*{)(.*))/
        block_indentation, text = $1, $2
        i += 1
        chunk = containers[i].code_chunk
        chunk.text = text + "\n"
        in_block = true
        block_end_token = case text
                             when /^{/
                               "}"
                             when /^do\b/
                               "end"
                             when /^(->|lambda)\s*({|do)/
                               $2 == "{" ? "}" : "end"
                             else
                               "}|end" # regex
                             end
      elsif in_block
        line =~ /^(\s*)(.*)/
        indentation, text = $1, $2
        if indentation.length <= block_indentation.length
          if text =~ /^#{block_end_token}/
            chunk.text << line
          end
          in_block = false
        else
          chunk.text << line
        end
      end
    end
    containers.each do |thing|
      text = thing.code_chunk.text
      text.strip! if text
    end
  end

end
end
