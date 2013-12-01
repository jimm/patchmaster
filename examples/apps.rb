# This simple example file shows how to connect two apps on the Mac.
#
# First, you must open the Audo MIDI Setup application, enable IAC, and add
# two more ports.

input  1, :app, 'IAC-in'        # The first port you added
output 2, :app, 'IAC-out'       # The second port you added

FULL_VOLUME = [CONTROLLER, CC_VOLUME, 127]

trigger :app, [NOTE_ON, 60, 127] { next_patch }
trigger :app, [NOTE_ON, 61, 127] { prev_patch }

song "First Song" do
  patch "Sax" do
    start_bytes FULL_VOLUME
    connection :app, :app, 1 do
      prog_chg 64
    end
  end
  patch "Piano" do
    start_bytes FULL_VOLUME
    connection :app, :app, 1 do
      prog_chg 2
    end
  end
  patch "Octave Down" do
    start_bytes FULL_VOLUME
    connection :app, :app, 1 do
      transpose -12
    end
  end
  patch "Can't Miss This Note" do
    start_bytes FULL_VOLUME
    connection :app, :app, 1 do
      filter do |conn, bytes|
        if bytes.note_on?
          bytes[1] = 64         # all notes become note 64
        end
        bytes
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
  patch "Up 'n Down" do
    connection :app, :app, 1 do
      prog_chg 2
      transpose 0
      filter do |conn, bytes|
        # Add more bytes to outgoing b array (MIDI channel 1)
        bytes + [CONTROLLER + 0, CC_VOLUME, time_based_volume]
      end
    end
    stop_bytes FULL_VOLUME
  end
end
