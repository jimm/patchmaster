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

  def message(name, messages)
    @pm.messages[name.downcase] = [name, messages]
  end

  def message_key(key_or_sym, name)
    if name.is_a?(Symbol)
      name, key_or_sym = key_or_sym, name
      output_message_key_deprecation_warning
    end
    if key_or_sym.is_a?(String) && name.is_a?(String)
      if name.length == 1 && key_or_sym.length > 1
        name, key_or_sym = key_or_sym, name
        output_message_key_deprecation_warning
      elsif name.length == 1 && key_or_sym.length == 1
        raise "message_key: since both name and key are one-character strings, I can't tell which is which. Please make the name longer."
      end
    end
    @pm.bind_message(name, to_binding_key(key_or_sym))
  end

  def code_key(key_or_sym, proc=nil, &block)
    ck = CodeKey.new(to_binding_key(key_or_sym), proc || block)
    @pm.bind_code(ck)
    @code_keys << ck
  end

  def trigger(instrument_sym, message, proc = nil, &block)
    instrument = @inputs[instrument_sym]
    raise "trigger: error finding instrument #{instrument_sym}" unless instrument
    t = Trigger.new(message, proc || block)
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

  def start_messages(messages)
    @patch.start_messages = messages
  end

  def stop_messages(messages)
    @patch.stop_messages = messages
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

  def bank(msb, lsb=nil)
    @conn.bank_msb = msb
    @conn.bank_lsb = lsb
  end

  def bank_msb(msb)
    @conn.bank_msb = msb
  end

  def bank_lsb(lsb)
    @conn.bank_lsb = lsb
  end

  def prog_chg(prog)
      @conn.pc_prog = prog
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

  def filter(proc=nil, &block)
    @conn.filter = Filter.new(proc || block)
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

  private

  # Translate symbol like :f1 to the proper function key value.
  def to_binding_key(key_or_sym)
    if key_or_sym.is_a?(Symbol) && PM::Main::FUNCTION_KEY_SYMBOLS[key_or_sym]
      key_or_sym = PM::Main::FUNCTION_KEY_SYMBOLS[key_or_sym]
    end
  end

  def output_message_key_deprecation_warning
    $stderr.puts "WARNING: the arguments to message_key are now key first, then name."
    $stderr.puts "I will use #{name} as the name and #{key_or_sym} as the key for now."
    $stderr.puts "Please swap them for future compatability."
  end

end
end
