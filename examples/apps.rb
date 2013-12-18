# This simple example file shows how to connect two apps on the Mac.
#
# First, you must open the Audo MIDI Setup application, enable IAC, and add
# two more ports.

input  1, :app_in, 'IAC-in'     # The first port you added
output 2, :app_out, 'IAC-out'   # The second port you added

def full_volume
  start_bytes [CONTROLLER, CC_VOLUME, 127]
end

trigger :app_in, [NOTE_ON+2, 0, 127] { next_patch }
trigger :app_in, [NOTE_ON+2, 1, 127] { prev_patch }

song "First Song" do
  patch "Bass" do
    full_volume
    connection :app_in, 1, :app_out, 1 do
      prog_chg 34
    end
  end
  patch "Piano" do
    full_volume
    connection :app_in, 1, :app_out, 1 do
      prog_chg 2
    end
  end
  patch "Chords & Bass Layers" do
    full_volume
    # Chords
    connection :app_in, 1, :app_out, 1 do
      prog_chg 95
      filter do |conn, bytes|
        if bytes.note_on?
          bytes[2] = 64 unless bytes[2] == 0
          bytes += [bytes[0], bytes[1] + 5, bytes[2]]
          bytes += [bytes[0], bytes[1] - 5, bytes[2]]
        end
      end
    end
    # Bass
    connection :app_in, 1, :app_out, 2 do
      prog_chg 38
      filter do |conn, bytes|
        if bytes.note_on?
          bytes[1] -= 12
          bytes += [bytes[0], bytes[1] - 12, bytes[2]]
        end
      end
    end
  end
end

def time_based_volume
  t = Time.now.to_f             # to_f gives sub-second accuracy
  unit_offset = Math.sin(t)     # -1 .. 1
  volume = (unit_offset * 64) + 64
  volume = 127 if volume == 128
  volume
end

song "LFO Volume" do
  notes <<EOS
The time_based_volume function
outputs a value that changes
over time.

The filter injects volume
commands after every MIDI
message and calls
time_based_volume.
EOS
  patch "Up 'n Down" do
    connection :app_in, 1, :app_out, 1 do
      prog_chg 2
      transpose 0
      filter do |conn, bytes|
        # Add more bytes to outgoing b array (MIDI channel 1)
        bytes + [CONTROLLER + 0, CC_VOLUME, time_based_volume]
      end
    end
    stop_bytes [CONTROLLER, CC_VOLUME, 127]
  end
end
