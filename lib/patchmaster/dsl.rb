require 'unimidi'

module PM

# Implements a DSL for describing a PatchMaster setup.
class DSL

  include PM

  def initialize(no_midi=false)
    @no_midi = no_midi
    @pm = PatchMaster.instance
  end

  def load(file)
    contents = IO.read(file)
    @filters = []
    instance_eval(contents)
    read_filters(contents)
  end

  def input(port_num, sym, name=nil)
    @pm.inputs[sym] = InputDevice.new(name || sym.to_s, port_num, @no_midi)
  rescue => ex
    raise "error creating input device \"#{name}\" on input port #{port_num}: #{ex}"
  end
  alias_method :in, :input

  def output(port_num, sym, name=nil)
    @pm.outputs[sym] = OutputDevice.new(name || sym.to_s, port_num, @no_midi)
  rescue => ex
    raise "error creating output device \"#{name}\" on output port #{port_num}: #{ex}"
  end
  alias_method :out, :output

  def song(name)
    @song = Song.new(name)      # ctor saves into @pm.all_songs
    yield @song if block_given?
  end

  def patch(name)
    @patch = Patch.new(name)
    @song << @patch
    yield @patch if block_given?
  end

  def start_bytes(bytes)
    @patch.start_bytes = bytes
  end

  def connection(in_sym, in_chan, out_sym, out_chan)
    input = @pm.inputs[in_sym]
    raise "can't find input instrument #{in_sym}" unless input
    output = @pm.outputs[out_sym]
    raise "can't find outputput instrument #{out_sym}" unless output

    @conn = Connection.new(input, in_chan, output, out_chan)
    @patch << @conn
    yield @conn if block_given?
  end
  alias_method :conn, :connection
  alias_method :c, :connection

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

  def filter(&block)
    @conn.filter = Filter.new(block)
    @filters << @conn.filter
  end
  alias_method :f, :filter

  def song_list(name, song_names)
    sl = SongList.new(name)
    @pm.song_lists << sl
    song_names.each do |sn|
      song = @pm.all_songs.find(sn)
      raise "song \"#{sn}\" not found (song list \"#{name}\")" unless song
      sl << song
    end
  end

  # ****************************************************************

  def save(file)
    File.open(file, 'w') { |f|
      save_instruments(f)
      save_songs(f)
      save_song_lists(f)
    }
  end

  def save_instruments(f)
    @pm.inputs.each { |sym, instr|
      f.puts "input #{instr.port_num}, :#{sym}, #{quoted(instr.name)}"
    }
    @pm.outputs.each { |sym, instr|
      f.puts "output #{instr.port_num}, :#{sym}, #{quoted(instr.name)}"
    }
    f.puts
  end

  def save_songs(f)
    @pm.all_songs.songs.each do |song|
      f.puts "song #{quoted(song.name)} do"
      song.patches.each { |patch| save_patch(f, patch) }
      f.puts "end"
      f.puts
    end
  end

  def save_patch(f, patch)
    f.puts "  patch #{quoted(patch.name)} do"
    f.puts "    start_bytes #{patch.start_bytes.inspect}" if patch.start_bytes
    patch.connections.each { |conn| save_connection(f, conn) }
    f.puts "  end"
  end

  def save_connection(f, conn)
    in_sym = @pm.inputs.patch(conn.input)
    in_chan = conn.input_chan ? conn.input_chan + 1 : 'nil'
    out_sym = @pm.outputs.patch(conn.output)
    out_chan = conn.output_chan + 1
    f.puts "    conn :#{in_sym}, #{in_chan}, #{out_sym}, #{out_chan} do"
    f.puts "      prog_chg #{conn.pc_prog}" if conn.pc?
    f.puts "      zone #{conn.note_num_to_name(conn.zone.begin)}, #{conn.note_num_to_name(conn.zone.end)}" if conn.zone
    f.puts "      xpose #{conn.xpose}" if conn.xpose
    f.puts "      filter #{conn.filter.text}" if conn.filter
    f.puts "    end"
  end

  def save_song_lists(f)
    @pm.song_lists.each do |sl|
      next if sl == @pm.all_songs
      f.puts "song_list #{quoted(sl.name)}, ["
      @pm.all_songs.songs.each do |song|
        f.puts "  #{quoted(song.name)},"
      end
      f.puts "]"
    end
  end

  def quoted(str)
    "\"#{str.gsub('"', "\\\"")}\"" # ' <= un-confuse Emacs font-lock
  end

  # ****************************************************************

  private

  def input_port(port)
    if @no_midi
      MockInputPort.new
    else
      UniMIDI::Input.all[port].open
    end
  end

  def output_port(port)
    if @no_midi
      MockOutputPort.new
    else
      UniMIDI::Output.all[port].open
    end
  end

  # Extremely simple filter text reader. Relies on indentation to detect end
  # of filter block.
  def read_filters(contents)
    i = 0
    in_filter = false
    filter_indentation = nil
    filter_end_token = nil
    contents.each_line do |line|
      if line =~ /^(\s*)filter\s*(.*)/
        filter_indentation, text = $1, $2
        @filters[i].text = text + "\n"
        in_filter = true
        filter_end_token = case text
                             when /^{/
                               "}"
                             when /^do\b/
                               "end"
                             when /^lambda\s*({|do)/
                               $1 == "{" ? "}" : "end"
                             else
                               "}|end" # regex
                             end
      elsif in_filter
        line =~ /^(\s*)(.*)/
        indentation, text = $1, $2
        if indentation.length <= filter_indentation.length
          if text =~ /^#{filter_end_token}/
            @filters[i].text << line
          end
          i += 1
          in_filter = false
        else
          @filters[i].text << line
        end
      end
    end
  end

end
end
