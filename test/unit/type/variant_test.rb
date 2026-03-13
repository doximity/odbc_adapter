require 'unit_test_helper'
require 'odbc_adapter/type/internal/snowflake_variant'
require 'odbc_adapter/type/variant'

class VariantTest < Minitest::Test
  def subject
    ODBCAdapter::Type::Variant.new
  end

  def test_type_is_variant
    assert_equal :variant, subject.type
  end

  def test_deserialize_json_string_to_hash
    result = subject.deserialize('{"key":"value"}')
    assert_equal({ 'key' => 'value' }, result)
  end

  def test_deserialize_json_string_to_array
    result = subject.deserialize('[1,2,3]')
    assert_equal [1, 2, 3], result
  end

  def test_deserialize_invalid_json_returns_nil
    assert_nil subject.deserialize('not valid json {')
  end

  def test_deserialize_nil_returns_nil
    assert_nil subject.deserialize(nil)
  end

  def test_deserialize_snowflake_variant_returns_internal_data
    data = { 'foo' => 1 }
    sv = ODBCAdapter::Type::SnowflakeVariant.new(data)
    assert_equal data, subject.deserialize(sv)
  end

  def test_cast_passes_through_hash
    val = { 'x' => 1 }
    assert_equal val, subject.cast(val)
  end

  def test_cast_passes_through_nil
    assert_nil subject.cast(nil)
  end

  def test_cast_passes_through_string
    assert_equal 'raw', subject.cast('raw')
  end

  def test_serialize_wraps_value_in_snowflake_variant
    result = subject.serialize({ 'a' => 1 })
    assert_instance_of ODBCAdapter::Type::SnowflakeVariant, result
    assert_equal({ 'a' => 1 }, result.internal_data)
  end

  def test_serialize_nil_returns_nil
    assert_nil subject.serialize(nil)
  end

  def test_changed_in_place_returns_false_when_equal
    refute subject.changed_in_place?('{"x":1}', { 'x' => 1 })
  end

  def test_changed_in_place_returns_true_when_different
    assert subject.changed_in_place?('{"x":1}', { 'x' => 2 })
  end

  def test_accessor_returns_string_keyed_hash_accessor
    assert_equal ActiveRecord::Store::StringKeyedHashAccessor, subject.accessor
  end
end
