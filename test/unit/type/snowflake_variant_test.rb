require 'unit_test_helper'
require 'odbc_adapter/type/internal/snowflake_variant'

class SnowflakeVariantTest < Minitest::Test
  def test_stores_internal_data
    sv = ODBCAdapter::Type::SnowflakeVariant.new({ 'k' => 1 })
    assert_equal({ 'k' => 1 }, sv.internal_data)
  end

  def test_internal_data_with_string
    sv = ODBCAdapter::Type::SnowflakeVariant.new('hello')
    assert_equal 'hello', sv.internal_data
  end

  def test_internal_data_with_nil
    sv = ODBCAdapter::Type::SnowflakeVariant.new(nil)
    assert_nil sv.internal_data
  end

  def test_quote_appends_variant_cast
    adapter = Minitest::Mock.new
    adapter.expect(:quote, "'hello'", ['hello'])

    sv = ODBCAdapter::Type::SnowflakeVariant.new('hello')
    result = sv.quote(adapter)

    assert_equal "'hello'::VARIANT", result
    adapter.verify
  end

  def test_quote_with_hash_value
    adapter = Minitest::Mock.new
    adapter.expect(:quote, "OBJECT_CONSTRUCT('k','v')", [{ 'k' => 'v' }])

    sv = ODBCAdapter::Type::SnowflakeVariant.new({ 'k' => 'v' })
    result = sv.quote(adapter)

    assert_equal "OBJECT_CONSTRUCT('k','v')::VARIANT", result
    adapter.verify
  end
end
