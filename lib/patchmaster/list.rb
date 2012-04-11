require 'delegate'

module PM

# A list (Array) of things with a cursor. +@curr+ is an integer index into
# an array of data.
#
# Delegates to an Array, so Array methods work here, too.
class List < SimpleDelegator

  def initialize
    super([])
  end

  # Inserts +data+ before +before_this+. If +before_this+ is not in our
  # list, +data+ is inserted at the beginning of the list.
  def insert_before(before_this, data)
    idx = index(before_this) || 0
    self[idx, 0] = data
  end

  # Inserts +data+ after +after_this+. If +after_this+ is not in our list,
  # +data+ is inserted at the end of the list.
  def insert_after(after_this, data)
    idx = index(after_this) || length-1
    self[idx + 1, 0] = data
  end

  def first?
    @curr == 0
  end

  def first
    if !empty? && @curr != 0
      @curr = 0
    end
    curr
  end

  def next
    if @curr == nil || @curr >= length - 1
      @curr = nil
    else
      @curr += 1
    end
    curr
  end

  def curr
    @curr ? self[@curr] : nil
  end

  # This does not change what is stored at the current location. Rather,
  # it moves this list's cursor to point to +data+ and returns +data+.
  def curr=(data)
    if curr != data
      @curr = index(data)
    end
    data
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
    if !empty? && !last?
      @curr = length - 1
    end
    curr
  end

  def last?
    @curr == nil || @curr == length - 1
  end

  def remove(data)
    return unless include?(data)
    __getobj__.remove(data)
    if empty?
      @curr = nil
    elsif @curr >= length
      @curr = length - 1
    end
  end

  # For debugging
  def to_s
    "List(#{empty? ? 'empty' : self[0].class.name}), size #{size}, curr index #{@curr}"
  end

end
end
