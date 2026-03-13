require 'unit_test_helper'
require 'odbc_adapter/type/array_of'

class ArrayOfTest < Minitest::Test
  def integer_array_type
    ODBCAdapter::Type.array_of(ActiveRecord::Type::Integer.new)
  end

  def string_array_type
    ODBCAdapter::Type.array_of(ActiveRecord::Type::String.new)
  end

  def test_factory_creates_a_class
    assert_kind_of Class, integer_array_type
  end

  def test_factory_creates_subclass_of_ar_type_value
    assert integer_array_type.ancestors.include?(ActiveRecord::Type::Value)
  end

  def test_cast_value_parses_json_string_to_array
    type = integer_array_type.new
    result = type.cast_value('[1, 2, 3]')
    assert_equal [1, 2, 3], result
  end

  def test_cast_value_casts_elements_with_inner_type
    type = integer_array_type.new
    result = type.cast_value('["4", "5"]')
    assert_equal [4, 5], result
  end

  def test_cast_value_returns_non_strings_unchanged
    type = integer_array_type.new
    arr = [1, 2]
    assert_equal arr, type.cast_value(arr)
  end

  def test_cast_value_invalid_json_returns_nil_mapped
    type = integer_array_type.new
    # invalid JSON → rescue returns nil → nil.map raises
    # The implementation does base_array.map, so invalid JSON → nil → error
    # This tests that bad input propagates predictably
    assert_raises(NoMethodError) { type.cast_value('not json') }
  end

  def test_serialize_maps_elements_through_inner_type
    type = string_array_type.new
    result = type.serialize(%w[a b])
    assert_equal %w[a b], result
  end

  def test_serialize_nil_returns_nil
    type = integer_array_type.new
    assert_nil type.serialize(nil)
  end

  def test_serialize_converts_to_array
    type = integer_array_type.new
    result = type.serialize([1, 2])
    assert_equal [1, 2], result
  end

  def test_changed_in_place_same_data
    type = integer_array_type.new
    refute type.changed_in_place?('[1,2]', [1, 2])
  end

  def test_changed_in_place_different_data
    type = integer_array_type.new
    assert type.changed_in_place?('[1,2]', [1, 3])
  end
end
