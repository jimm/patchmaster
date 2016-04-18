module PM

# A Song is a named list of Patches.
class Song

  attr_accessor :name, :patches, :notes

  def initialize(name)
    @name = name
    @patches = []
    PatchMaster.instance.all_songs << self
  end

  def <<(patch)
    @patches << patch
  end

end
end
