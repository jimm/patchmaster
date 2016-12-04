class Formatter

  NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
  NOTE_STATUS_NAMES = %w(off on pp)
  SYS_MSG_NAMES = %w(sysex f1 songptr songsel f4 f5 tunereq eox clock f9 start cont stop fd actsens reset)

  def self.note_num_to_name(n)
    oct = (n / 12) - 1
    note = NOTE_NAMES[n % 12]
    "#{note}#{oct}"
  end

  def self.to_s(bytes, hex=false)
    hn = bytes.high_nibble
    chan = bytes.channel + 1
    case hn
    when PM::NOTE_OFF, PM::NOTE_ON, PM::POLY_PRESSURE
      note_s(bytes, hex)
    when PM::CONTROLLER
      "#{PM::CONTROLLER_NAMES[bytes[1]]}, #{num_s(bytes[2], hex)}, ch #{chan}"
    when PM::PROGRAM_CHANGE
      "pc #{num_s(bytes[1], hex)}, ch #{chan}"
    when PM::CHANNEL_PRESSURE
      "cp #{num_s(bytes[1], hex)}, ch #{chan}"
    when PM::PITCH_BEND
      "pb #{num_s(bytes[1], hex)}, #{num_s(bytes[1], hex)}, ch #{chan}"
    else
      SYS_MSG_NAMES[bytes[0] - 0xf0]
    end
  end

  private

  def self.note_s(bytes, hex)
    note_name = note_num_to_name(bytes[1])
    val = num_s(bytes[2], hex)
    chan = bytes.channel + 1
    "#{NOTE_STATUS_NAMES[(bytes[0]/16)-8]} #{note_name}, #{val}, ch #{chan}"
  end

  def self.num_s(val, hex=false)
    if hex
      "%02x" % val
    else
      val.to_s
    end
  end
end
