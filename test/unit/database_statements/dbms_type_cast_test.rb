# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/database_statements'

# Host that exposes the private dbms_type_cast for testing
class DbmsTypeCastHost
  include ODBCAdapter::DatabaseStatements

  # Expose private method
  def type_cast(columns, rows)
    dbms_type_cast(columns, rows)
  end

  # Not used in dbms_type_cast but required by the module
  def prepared_statements = false
  def database_metadata = nil
end

StubCol = Struct.new(:type, :scale, :name)

class DbmsTypeCastTest < Minitest::Test
  def host
    DbmsTypeCastHost.new
  end

  def cast(col_type, value, scale: 0)
    col = StubCol.new(col_type, scale, 'col')
    rows = [[value]]
    host.type_cast([col], rows)
    rows[0][0]
  end

  def test_nil_passes_through
    assert_nil cast(ODBC::SQL_VARCHAR, nil)
  end

  # --- varchar / string types ---

  def test_varchar_encodes_to_utf8
    val = 'hello'.dup.force_encoding('ASCII')
    result = cast(ODBC::SQL_VARCHAR, val)
    assert_equal Encoding::UTF_8, result.encoding
    assert_equal 'hello', result
  end

  def test_char_encodes_to_utf8
    result = cast(ODBC::SQL_CHAR, 'world'.dup.force_encoding('ASCII'))
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_longvarchar_encodes_to_utf8
    result = cast(ODBC::SQL_LONGVARCHAR, 'long'.dup.force_encoding('ASCII'))
    assert_equal Encoding::UTF_8, result.encoding
  end

  # --- numeric types ---

  def test_decimal_scale_zero_casts_to_integer
    result = cast(ODBC::SQL_DECIMAL, '42', scale: 0)
    assert_equal 42, result
    assert_kind_of Integer, result
  end

  def test_decimal_scale_positive_casts_to_float
    result = cast(ODBC::SQL_DECIMAL, '3.14', scale: 2)
    assert_in_delta 3.14, result, 0.001
    assert_kind_of Float, result
  end

  def test_numeric_scale_zero_casts_to_integer
    result = cast(ODBC::SQL_NUMERIC, '7', scale: 0)
    assert_equal 7, result
  end

  def test_real_casts_to_float
    result = cast(ODBC::SQL_REAL, '1.5')
    assert_in_delta 1.5, result, 0.001
    assert_kind_of Float, result
  end

  def test_float_casts_to_float
    result = cast(ODBC::SQL_FLOAT, '2.5')
    assert_kind_of Float, result
  end

  def test_double_casts_to_float
    result = cast(ODBC::SQL_DOUBLE, '3.5')
    assert_kind_of Float, result
  end

  def test_integer_casts_to_integer
    result = cast(ODBC::SQL_INTEGER, '99')
    assert_equal 99, result
    assert_kind_of Integer, result
  end

  def test_smallint_casts_to_integer
    result = cast(ODBC::SQL_SMALLINT, '10')
    assert_kind_of Integer, result
  end

  def test_tinyint_casts_to_integer
    result = cast(ODBC::SQL_TINYINT, '1')
    assert_kind_of Integer, result
  end

  def test_bigint_casts_to_integer
    result = cast(ODBC::SQL_BIGINT, '12345678901234')
    assert_kind_of Integer, result
  end

  # --- boolean ---

  def test_bit_one_casts_to_true
    result = cast(ODBC::SQL_BIT, 1)
    assert_equal true, result
  end

  def test_bit_zero_casts_to_false
    result = cast(ODBC::SQL_BIT, 0)
    assert_equal false, result
  end

  # --- date / time ---

  def test_date_type_casts_to_date
    val = Date.new(2024, 1, 15)
    result = cast(ODBC::SQL_DATE, val)
    assert_kind_of Date, result
  end

  def test_type_date_casts_to_date
    val = Date.new(2024, 6, 1)
    result = cast(ODBC::SQL_TYPE_DATE, val)
    assert_kind_of Date, result
  end

  def test_time_type_casts_to_time
    val = Time.now
    result = cast(ODBC::SQL_TIME, val)
    assert_kind_of Time, result
  end

  def test_timestamp_casts_to_datetime
    val = Time.now
    result = cast(ODBC::SQL_TIMESTAMP, val)
    assert_kind_of DateTime, result
  end

  def test_type_timestamp_casts_to_datetime
    val = Time.now
    result = cast(ODBC::SQL_TYPE_TIMESTAMP, val)
    assert_kind_of DateTime, result
  end

  # --- binary ---

  def test_binary_passes_through
    val = 'raw bytes'
    result = cast(ODBC::SQL_BINARY, val)
    assert_equal val, result
  end

  # --- unknown type raises ---

  def test_unknown_type_raises
    # The raise message tries to call @raw_connection.types — stub it on the host
    host_with_conn = DbmsTypeCastHost.new
    host_with_conn.instance_variable_set(
      :@raw_connection,
      Struct.new(:stub) { def types(_code) = [['UNKNOWN']] }.new(nil)
    )
    col  = StubCol.new(9999, 0, 'col')
    rows = [['x']]
    assert_raises(RuntimeError) { host_with_conn.type_cast([col], rows) }
  end

  # --- multiple rows and columns ---

  def test_casts_multiple_rows
    col = StubCol.new(ODBC::SQL_INTEGER, 0, 'n')
    rows = [['1'], ['2'], ['3']]
    host.type_cast([col], rows)
    assert_equal [1, 2, 3], rows.map { |r| r[0] }
  end
end
