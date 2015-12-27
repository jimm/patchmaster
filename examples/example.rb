input  0, :mb, 'midiboard'
input  1, :ws_in, 'WaveStation'

output 1, :ws_out, 'WaveStation'
output 2, :kz, 'K2000R'
output 4, :sj                   # Name will come from UNIMidi

# In this setup, output 4 => SJ => MIDI thru => Drum machine. This lets me
# refer to the same output as both :sj and :drums. There's an equivalent
# alias_input command as well.
alias_output :drums, :sj

message "Tune Request", [TUNE_REQUEST]

full_volumes = (0...MIDI_CHANNELS).collect { |chan| [CONTROLLER + chan, CC_VOLUME, 127]}.flatten
message "Full Volume", full_volumes

message_key :f1, "Tune Request"
message_key :f2, "Full Volume"

trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_5, 127] { next_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_6, 127] { prev_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_7, 127] { next_song }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_8, 127] { prev_song }
trigger :mb, [CONTROLLER, 126, 127] { send_message "Tune Request" }

song "First Song" do

  notes <<EOS
  C
These are the words
          F            C
They are very clever words
     Ab mi
And deep
        G7
Oh, so deep

        C         C/B
This chorus does not
 C7/Bb     Ami
Refer to itself
        F
Don't think too hard, or
       G7
Your head
Will
  C
Explode
EOS

  patch "First Song, First Patch" do
    start_bytes [TUNE_REQUEST]
    connection :mb, :kz, 2 do  # all chans from :mb, out to chan 2 on :kz
      prog_chg 64
      zone C4, B5
      transpose 12
    end
    connection :ws_in, 6, :sj, 4 do  # only chan 6 from :ws_in, out to chan 4 on :sj
      prog_chg 100
      zone C4, B5
      filter { |conn, bytes|
        if bytes.note_off?
          bytes[2] -= 1 unless bytes[2] == 0 # decrease velocity by 1
        end
        bytes
      }
    end
    conn :ws_in, 6, :ws_out, 6
  end
  patch "First Song, Second Patch"
end

song "Second Song" do
  patch "Second Song, First Patch" do
    c :mb, :sj, 4 do
      pc 22
      z D4
    end
    c :ws_in, :ws_out, 6 do
      zone C4..B5
      filter { |c, b| b }       # no-op
    end
  end
end

song_list "Tonight's Song List", [
  "First Song",
  "Second Song"
]
