# frozen_string_literal: true

require 'unit_test_helper'
require 'ostruct'
require 'odbc_adapter/type/object'

class SnowflakeObjectTest < Minitest::Test
  def subject
    ODBCAdapter::Type::SnowflakeObject.new
  end

  def test_cast_value_json_string_to_hash
    result = subject.cast_value('{"key":"value"}')
    assert_equal({ 'key' => 'value' }, result)
  end

  def test_cast_value_hash_passes_through
    hash = { 'a' => 1 }
    assert_equal hash, subject.cast_value(hash)
  end

  def test_cast_value_invalid_json_returns_nil
    assert_nil subject.cast_value('not json {')
  end

  def test_serialize_hash_returns_hash
    hash = { 'a' => 1, 'b' => 2 }
    assert_equal hash, subject.serialize(hash)
  end

  def test_serialize_nil_returns_nil
    assert_nil subject.serialize(nil)
  end

  def test_serialize_calls_to_h
    obj = OpenStruct.new(a: 1)
    result = subject.serialize(obj)
    assert_equal({ a: 1 }, result)
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
