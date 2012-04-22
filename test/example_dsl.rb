input  0, :mb, 'midiboard'
input  1, :ws, 'WaveStation'
output 1, :ws, 'WaveStation'
output 2, :kz, 'K2000R'
output 4, :sj                   # name will be "sj"

trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_5, 0] { next_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_6, 0] { prev_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_7, 0] { next_song }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_8, 0] { prev_song }

song "First Song" do
  patch "First Song, First Patch" do
    start_bytes [TUNE_REQUEST]
    stop_bytes [STOP]
    connection :mb, nil, :kz, 2 do  # all chans from :mb, out to chan 2 on :kz
      prog_chg 64
      zone C4, B5
      transpose 12
    end
    connection :ws, 6, :sj, 4 do  # only chan 6 from :ws_kbd, out to chan 4 on :sj
      prog_chg 100
      zone C4, B5
      filter { |connection, bytes|
        if bytes.note_off?
          bytes[2] -= 1 unless bytes[2] == 0 # decrease velocity by 1
        end
      }
    end
    conn :ws, 6, :ws, 6
  end
  patch "First Song, Second Patch"
end

song "Second Song" do
  patch "Second Song, First Patch" do
    c :mb, :any, :sj, 4 do
      pc 22
      z D4
    end
    c :ws, :any, :ws, 6 do
      zone C4..B5
      filter { |c, b| b }       # no-op
    end
    c :ws, :any, :kz, 3 do
      filter { |c, b| b[0] += 1 }
    end
  end
end

song_list "Tonight's Song List", [
  "First Song",
  "Second Song"
]
