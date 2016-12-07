require 'test_helper'

class FormatterTest < Test::Unit::TestCase
  def test_note_num_to_name
    assert_equal "C4", Formatter.note_num_to_name(PM::C4)
  end
end
