require 'unit_test_helper'
require 'odbc_adapter/type/snowflake_integer'

class SnowflakeIntegerTest < Minitest::Test
  def subject
    ODBCAdapter::Type::SnowflakeInteger.new
  end

  def test_inherits_from_big_integer
    assert_kind_of ActiveRecord::Type::BigInteger, subject
  end

  def test_cast_auto_generate_passes_through
    assert_equal :auto_generate, subject.cast(:auto_generate)
  end

  def test_cast_integer_string
    assert_equal 42, subject.cast('42')
  end

  def test_cast_integer
    assert_equal 7, subject.cast(7)
  end

  def test_cast_nil_returns_nil
    assert_nil subject.cast(nil)
  end

  def test_cast_float_truncates
    assert_equal 3, subject.cast(3.9)
  end
end
