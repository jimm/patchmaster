require 'patchmaster/list'
require 'patchmaster/list_container'

module PM

# A Song is a named list of Patches with a cursor.
class Song

  attr_accessor :name, :patches

  include ListContainer

  def initialize(name)
    @name = name
    @patches = List.new
    PatchMaster.instance.all_songs << self
  end

  def <<(patch)
    @patches << patch
  end

end
end
