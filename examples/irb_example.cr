input  0, :mb, 'midiboard'
input  1, :ws_in, 'WaveStation'
output 1, :ws_out, 'WaveStation'
output 2, :kz, 'K2000R'
output 4, :sj                   # Name will come from UNIMidi

def setup1
  connection :mb, :kz, 1
  connection :ws_in, :sj, 4
end

def setup2
  connection :mb, :sj, 4
  connection :ws_in, :kz, 1
  transpose 12
end
