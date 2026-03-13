# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/type/type'

class TypeRegistrationTest < Minitest::Test
  # --- Array type constants ---

  def test_array_constants_are_classes
    [
      ODBCAdapter::Type::ArrayOfBigIntegers,
      ODBCAdapter::Type::ArrayOfIntegers,
      ODBCAdapter::Type::ArrayOfStrings
    ].each { |c| assert_kind_of Class, c }
  end

  def test_array_constants_are_independent
    refute_equal ODBCAdapter::Type::ArrayOfIntegers, ODBCAdapter::Type::ArrayOfStrings
  end

  def test_array_of_integers_can_cast_json_array
    result = ODBCAdapter::Type::ArrayOfIntegers.new.cast('[1,2,3]')
    assert_equal [1, 2, 3], result
  end

  # --- Registered types ---

  def test_variant_is_registered_with_odbc_adapter
    type = ActiveRecord::Type.lookup(:variant, adapter: :odbc)
    assert_kind_of ODBCAdapter::Type::Variant, type
  end

  def test_object_is_registered_with_odbc_adapter
    type = ActiveRecord::Type.lookup(:object, adapter: :odbc)
    assert_kind_of Object, type
  end

  def test_integer_is_registered_with_odbc_adapter
    type = ActiveRecord::Type.lookup(:integer, adapter: :odbc)
    assert_kind_of ODBCAdapter::Type::SnowflakeInteger, type
  end
end
