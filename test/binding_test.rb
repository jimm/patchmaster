require 'test_helper'
require 'patchmaster/curses/main'

class BindingTest < Test::Unit::TestCase

  def setup
    $global_code_key_value = nil
    @pm = PM::PatchMaster.instance
    @old_pm_gui = @pm.gui
    @pm.load(DSLTest::EXAMPLE_DSL)
    @pm.start
  end

  def teardown
    @pm.gui = @old_pm_gui
    @pm.stop
    @pm.init_data
    $global_code_key_value = nil
  end

  def test_code_binding
    code_bindings = @pm.instance_variable_get("@code_bindings".to_sym)
    code_key = code_bindings[Curses::Key::F3]
    code_key.run
    assert $global_code_key_value == 42
  end

  def test_message_binding
    message_bindings = @pm.instance_variable_get("@message_bindings".to_sym)
    msg = message_bindings[Curses::Key::F1]
    assert_equal "Tune Request", msg
  end

  def test_backward_message_key_args
    old_stderr = $stderr.dup
    $stderr.reopen("/dev/null", "w")

    dsl = PM::DSL.new
    dsl.message_key("Tune Request", :f9)

    message_bindings = @pm.instance_variable_get("@message_bindings".to_sym)
    msg = message_bindings[Curses::Key::F9]
    assert_equal "Tune Request", msg

    $stderr = old_stderr
  end

  def test_ambiguous_message_key_args
    dsl = PM::DSL.new
    dsl.message_key("a", "b")
    fail "expected error to be raised"
  rescue => ex
    assert true == true
  end
end
