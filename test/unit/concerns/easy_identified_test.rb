# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/concerns/easy_identified'

# Minimal ActiveRecord-like model for testing the concern.
# Defines save/save! before including so alias_method works.
class MockEasyIdentifiedModel
  attr_accessor :id, :save_called, :save_bang_called, :saved_options

  def initialize(id: nil)
    @id = id
    @save_called = false
    @save_bang_called = false
    @saved_options = {}
  end

  def save(**options)
    @save_called = true
    @saved_options = options
    true
  end

  def save!(**options)
    @save_bang_called = true
    @saved_options = options
    true
  end

  include ODBCAdapter::EasyIdentified
  # Prepend overrides retrieve_id without triggering a "method redefined" warning
  # because the method lives in a separate module, not the class itself.
  prepend(Module.new { def retrieve_id = 42 })
end

class EasyIdentifiedTest < Minitest::Test
  def model(id: nil)
    MockEasyIdentifiedModel.new(id: id)
  end

  def test_save_with_normal_id_skips_generation
    m = model(id: 1)
    m.save
    assert_equal 1, m.id
    assert m.save_called
  end

  def test_save_with_auto_generate_calls_retrieve_id
    m = model(id: :auto_generate)
    m.save
    assert_equal 42, m.id
  end

  def test_save_with_auto_generate_then_delegates_to_underlying_save
    m = model(id: :auto_generate)
    m.save
    assert m.save_called
  end

  def test_save_bang_with_normal_id_skips_generation
    m = model(id: 5)
    m.save!
    assert_equal 5, m.id
  end

  def test_save_bang_with_auto_generate_calls_retrieve_id
    m = model(id: :auto_generate)
    m.save!
    assert_equal 42, m.id
  end

  def test_generate_id_sets_id_from_retrieve_id_when_nil
    m = model(id: nil)
    m.generate_id
    assert_equal 42, m.id
  end

  def test_generate_id_force_new_overwrites_existing_id
    m = model(id: 99)
    m.generate_id(true)
    assert_equal 42, m.id
  end

  def test_generate_id_without_force_keeps_existing_non_nil_id
    m = model(id: 99)
    m.generate_id
    assert_equal 99, m.id
  end

  def test_save_passes_options_through
    m = model(id: 1)
    m.save(validate: false)
    assert_equal({ validate: false }, m.saved_options)
  end
end
