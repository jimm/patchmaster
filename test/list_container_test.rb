require 'test_helper'

class Outer
  attr_accessor :inners
  include PM::ListContainer
  def initialize
    @inners = PM::List.new
  end
end

class Inner
  attr_accessor :values
  include PM::ListContainer
  def initialize
    @values = PM::List.new
  end
end

class ListContainerTest < Test::Unit::TestCase

  def setup
    @outer = Outer.new

    @inner1 = Inner.new
    @inner1.values << 1
    @inner1.values << 2
    @outer.inners << @inner1

    @inner2 = Inner.new
    @inner2.values << :a
    @inner2.values << :b
    @outer.inners << @inner2

    @outer.first_inner
    @inner1.first_value
    @inner2.first_value
  end

  def test_pluralize
    assert_equal 'values', @outer.pluralize('value')
    assert_equal 'classes', @outer.pluralize('class')
    assert_equal 'inners', @outer.pluralize('inner')
  end

  def test_curr_inner
    assert_equal @inner1, @outer.curr_inner
  end

  def test_next_inner
    assert_equal @inner2, @outer.next_inner
  end

  def test_next_next
    @outer.next_inner
    assert_equal nil, @outer.next_inner
  end

  def test_set_curr
    assert_equal @inner1, @outer.inners.first
    @outer.first_inner
    @outer.curr_inner = @inner2
    assert_equal @inner2, @outer.curr_inner
  end

  def test_predicates
    assert @outer.first_inner?
    assert !@outer.last_inner?
  end

end
