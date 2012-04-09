module PM

# A list (Array) of things with a cursor. +@curr+ is an integer index into
# an array of data.
class List

  include Enumerable

  # If +enter_sym+ or +exit_sym+ are defined, they will be sent to a data
  # element when it becomes the current element or stops being the current
  # element.
  def initialize
    @data = []
    @curr = nil
  end

  # Adding data does not modify the cursor.
  def <<(data)
    @data << data
  end

  # Inserts +data+ before +before_this+. If +before_this+ is not in our
  # list, +data+ is inserted at the beginning of the list.
  def insert_before(before_this, data)
    idx = @data.index(before_this) || 0
    @data[idx, 0] = data
  end

  # Inserts +data+ after +after_this+. If +after_this+ is not in our list,
  # +data+ is inserted at the end of the list.
  def insert_after(after_this, data)
    idx = @data.index(after_this) || @data.length-1
    @data[idx + 1, 0] = data
  end

  def size
    @data.size
  end
  alias_method :length, :size

  def first?
    @curr == 0
  end

  def first
    if !@data.empty? && @curr != 0
      @curr = 0
    end
    curr
  end

  def next
    if @curr == nil || @curr >= @data.length - 1
      @curr = nil
    else
      @curr += 1
    end
    curr
  end

  def curr
    @curr ? @data[@curr] : nil
  end

  # This does not change what is stored at the current location. Rather,
  # it moves this list's cursor to point to +data+ and returns +data+.
  def curr=(data)
    if curr != data
      @curr = @data.index(data)
    end
    data
  end

  # Returns the +n+th data element. This method is not normally used to
  # access data because it does not change the cursor. It is used to peek
  # into the list's data array, for example during testing.
  def [](n)
    @data[n]
  end

  def prev
    if @curr == nil || @curr == 0
      @curr = nil
    else
      @curr -= 1
    end
    curr
  end

  def last
    if !@data.empty? && !last?
      @curr = @data.length - 1
    end
    curr
  end

  def last?
    @curr == nil || @curr == @data.length - 1
  end

  def remove(data)
    return unless @data.include?(data)
    @data[@data.index(data), 1] = []
    if @data.empty?
      @curr = nil
    elsif @curr >= @data.length
      @curr = @data.length - 1
    end
  end

  def each
    @data.each { |data| yield data }
  end

  # For debugging
  def to_s
    "List(#{@data.empty? ? 'empty' : @data[0].class.name}), size #{size}, curr index #{@curr}"
  end

end
end
