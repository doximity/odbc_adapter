# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/concerns/insert_attribute_stripper'

# Column stub with a type
StubColumnForStripper = Struct.new(:name, :type)

# Minimal model for testing the concern.
# Needs: save/save!, valid?, new_record?, attributes, columns, self[key]=
class MockStrippableModel
  attr_accessor :attributes, :first_save_result

  def initialize(is_new: true, valid: true, first_save_result: true)
    @new_record = is_new
    @valid = valid
    @first_save_result = first_save_result
    @attributes = {}
    @save_count = 0
  end

  def save(**_options)
    @save_count += 1
    @first_save_result
  end

  def save!(**_options)
    @save_count += 1
    true
  end

  def valid?
    @valid
  end

  def new_record?
    @new_record
  end

  def []=(key, val)
    @attributes[key] = val
  end

  attr_reader :save_count

  def self.columns
    @columns ||= []
  end

  class << self
    attr_writer :columns
  end

  def self.transaction
    yield
  end

  include ODBCAdapter::InsertAttributeStripper
end

class InsertAttributeStripperTest < Minitest::Test
  def setup
    MockStrippableModel.columns = []
  end

  def new_model_with_variant_column(variant_value: { 'k' => 1 })
    MockStrippableModel.columns = [
      StubColumnForStripper.new('data', :variant)
    ]
    m = MockStrippableModel.new(is_new: true, valid: true)
    m.attributes = { 'data' => variant_value }
    m
  end

  # --- new records strip unsafe columns ---

  def test_new_record_strips_variant_column_before_first_save
    m = new_model_with_variant_column(variant_value: { 'k' => 1 })
    m.save
    # After two saves, attributes should be restored
    assert_equal({ 'k' => 1 }, m.attributes['data'])
  end

  def test_new_record_calls_save_twice
    m = new_model_with_variant_column
    m.save
    assert_equal 2, m.save_count
  end

  def test_new_record_only_strips_variant_object_array_types
    MockStrippableModel.columns = [
      StubColumnForStripper.new('name', :string),
      StubColumnForStripper.new('data', :variant)
    ]
    m = MockStrippableModel.new(is_new: true, valid: true)
    m.attributes = { 'name' => 'Alice', 'data' => { 'x' => 1 } }
    m.save
    # String column should not be stripped
    assert_equal 'Alice', m.attributes['name']
  end

  # --- existing records are not stripped ---

  def test_existing_record_calls_save_once
    MockStrippableModel.columns = [StubColumnForStripper.new('data', :variant)]
    m = MockStrippableModel.new(is_new: false, valid: true)
    m.attributes = { 'data' => { 'k' => 1 } }
    m.save
    assert_equal 1, m.save_count
  end

  # --- invalid records (validate: false not set) ---

  def test_invalid_record_returns_result_of_base_save
    m = MockStrippableModel.new(is_new: true, valid: false)
    result = m.save
    # When invalid and validate not false, calls base save directly
    assert_equal true, result
    assert_equal 1, m.save_count
  end

  # --- first save failure short-circuits second save ---

  def test_first_save_failure_skips_second_save
    MockStrippableModel.columns = [StubColumnForStripper.new('data', :variant)]
    m = MockStrippableModel.new(is_new: true, valid: true, first_save_result: false)
    m.attributes = { 'data' => { 'k' => 1 } }
    result = m.save
    assert_equal false, result
    assert_equal 1, m.save_count
  end

  # --- save! path ---

  def test_save_bang_strips_and_restores_like_save
    m = new_model_with_variant_column
    m.save!
    assert_equal 2, m.save_count
    assert_equal({ 'k' => 1 }, m.attributes['data'])
  end

  # --- nil variant value not stripped ---

  def test_nil_variant_value_is_not_stripped
    MockStrippableModel.columns = [StubColumnForStripper.new('data', :variant)]
    m = MockStrippableModel.new(is_new: true, valid: true)
    m.attributes = { 'data' => nil }
    m.save
    assert_equal 1, m.save_count
  end

  # --- validate:false bypasses early return ---

  def test_validate_false_on_invalid_record_proceeds_with_strip_and_save
    MockStrippableModel.columns = [StubColumnForStripper.new('data', :variant)]
    m = MockStrippableModel.new(is_new: true, valid: false)
    m.attributes = { 'data' => { 'k' => 1 } }
    m.save(validate: false)
    assert_equal 2, m.save_count
  end
end
