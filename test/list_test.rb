require 'test_helper'

class SymTestNode

  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def entered
    @value += 1
  end

  def exited
    @value -= 1
  end
end
    

class ListTest < Test::Unit::TestCase

  def setup
    @list = PM::List.new
    @list << 42
    @list << :foo
    @inner = PM::List.new
    @inner << :bar
    @list << @inner

    @list.first
    @inner.first
  end

  def test_size
    assert_equal 3, @list.size
    assert_equal 3, @list.length
  end

  def test_insert_before
    @list.insert_before(:foo, :bar)
    @list.curr = 42
    assert_equal 42, @list.curr
    assert_equal :bar, @list.next
    assert_equal :foo, @list.next
    assert_equal @inner, @list.next
  end

  def test_insert_before_dne
    @list.insert_before(:does_not_exist, :bar)
    assert_equal :bar, @list.first
  end

  def test_insert_after
    @list.insert_after(:foo, :bar)
    @list.first
    assert_equal 42, @list.curr
    assert_equal :foo, @list.next
    assert_equal :bar, @list.next
    assert_equal @inner, @list.next
  end

  def test_insert_before_dne
    @list.insert_after(:does_not_exist, :bar)
    assert_equal :bar, @list.last
  end

  def test_curr
    assert_equal 42, @list.curr
  end

  def test_nil_curr
    assert_not_nil @list.curr
    @list.curr = nil
    assert_nil @list.curr
  end

  def test_next
    assert_equal :foo, @list.next
  end

  def test_next_when_at_end
    @list.next
    @list.next
    assert_nil @list.next
  end

  def test_prev
    @list.next
    assert_equal 42, @list.prev
  end

  def test_prev_when_at_end
    assert_nil @list.prev
  end

  def test_curr_after_next
    @list.next
    assert_equal :foo, @list.curr
  end

  def test_curr=
    @list.curr = @inner
    assert_equal @inner, @list.curr
  end

  def test_first
    assert @list.first?
    @list.next
    assert !@list.first?
  end

  def test_last
    @list.next
    assert !@list.last?
    @list.next
    assert @list.last?
  end

  def test_empty_end
    assert PM::List.new.last?
  end
end
