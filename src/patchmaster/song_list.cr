module PM

# A SongList is a list of Songs.
class SongList

  attr_accessor :name, :songs

  def initialize(name)
    @name = name
    @songs = [] of Song
  end

  def <<(song)
    @songs << song
  end

  # Returns the first Song that matches +name+. +name+ may be either a
  # Regexp or a String. The match will be made case-insensitive.
  def find(name_regex)
    name_regex = Regexp.new(name_regex.to_s, true) # make case-insensitive
    @songs.detect { |s| s.name =~ name_regex }
  end

  %w(first prev curr next last).each do |dir|
    instance_eval("def #{dir}_patch; @songs.curr.#{dir}_patch; end")
  end
end
end
