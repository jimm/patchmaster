# This simple example file shows how to connect two apps on the Mac.

input  0, :app, 'IAC'
output 0, :app, 'IAC'

song "First Song" do
  patch "First Song, First Patch" do
    connection :app, :app, 1 do
      prog_chg 64
    end
  end
  patch "First Song, Second Patch" do
    connection :app, :app, 1 do
      prog_chg 2
      transpose -12
    end
  end
end
