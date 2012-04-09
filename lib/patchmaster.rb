require 'patchmaster/consts'
require 'patchmaster/predicates'
require 'patchmaster/song_list'
require 'patchmaster/song'
require 'patchmaster/patch'
require 'patchmaster/connection'
require 'patchmaster/filter'
require 'patchmaster/io'
require 'patchmaster/patchmaster'
require 'patchmaster/dsl'
require 'patchmaster/app/main'

def message(str)
  PM::Main.instance.message(str)
end
