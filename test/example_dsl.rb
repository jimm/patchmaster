input  0, :mb, 'midiboard'
input  1, :ws, 'WaveStation'
output 2, :kz, 'K2000R'
output 4, :sj                   # name will be "sj"
output 6, :ws, 'WaveStation'

song "First Song" do
  patch "First Song, First Patch" do
    start_bytes [TUNE_REQUEST]
    connection :mb, nil, :kz, 2 do  # all chans from :mb, out to chan 2 on :kz
      prog_chg 64
      zone C4, B5
      transpose 12
    end
    connection :ws, 6, :sj, 4 do  # only chan 6 from :ws_kbd, out to chan 4 on :sj
      prog_chg 100
      zone C4, B5
      filter { |device, bytes|
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
    c :mb, nil, :sj, 4 do
      pc 22
      z D4
    end
    c :ws, nil, :ws, 6 do
      zone C4..B5
      filter { |d, b| b }       # no-op
    end
  end
end

song_list "Tonight's Song List", [
  "First Song",
  "Second Song"
]
