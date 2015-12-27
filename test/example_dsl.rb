input  0, :mb, 'midiboard'
inp    1, :ws_in, 'WaveStation'
output 1, :ws_out, 'WaveStation'
out    2, :kz, 'K2000R'
output 4, :sj

message "Tune Request", [TUNE_REQUEST]

full_volumes = (0...MIDI_CHANNELS).collect { |chan| [CONTROLLER + chan, CC_VOLUME, 127]}.flatten
message "Full Volume", full_volumes

message_key :f1, "Tune Request"
message_key :f2, "Full Volume"

$global_code_key_value = nil

code_key :f3 do
  $global_code_key_value = 42
end
code_key(:f4) { $global_code_key_value = 99 }

trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_5, 0] { next_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_6, 0] { prev_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_7, 0] { next_song }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_8, 0] { prev_song }
trigger :mb, [CONTROLLER, 126, 127] { send_message "Tune Request" }

song "First Song" do
  patch "First Song, First Patch" do
    start_bytes [TUNE_REQUEST]
    stop_bytes [STOP]
    connection :mb, nil, :kz, 2 do  # all chans from :mb, out to chan 2 on :kz
      prog_chg 64
      zone C4, B5
      transpose 12
    end
    connection :ws_in, 6, :sj, 4 do  # only chan 6 from :ws_in, out to chan 4 on :sj
      prog_chg 2, 100                # bank 2, prog 100
      zone C4, B5
      filter { |connection, bytes|
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
    c :ws_in, :kz, 3 do
      filter { |c, b| b[0] += 1; b }
    end
  end
end

song_list "Tonight's Song List", [
  "First Song",
  "Second Song"
]
