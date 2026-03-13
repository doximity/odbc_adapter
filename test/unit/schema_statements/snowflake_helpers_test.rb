require 'unit_test_helper'
require 'odbc_adapter/schema_statements'

# Host class that exposes the private helper methods.
class SchemaStatementsHost
  include ODBCAdapter::SchemaStatements

  # Expose private helpers
  def extract_default(val)
    extract_default_from_snowflake(val)
  end

  def extract_data_type(type)
    extract_data_type_from_snowflake(type)
  end

  def extract_column_size(type_info)
    extract_column_size_from_snowflake(type_info)
  end

  def build_sql_type(native, limit, scale)
    construct_sql_type(native, limit, scale)
  end

  def name_regex_for(name)
    name_regex(name)
  end
end

class SnowflakeHelpersTest < Minitest::Test
  def host
    SchemaStatementsHost.new
  end

  # --- extract_default_from_snowflake ---

  def test_extract_default_nil_returns_nil
    assert_nil host.extract_default(nil)
  end

  def test_extract_default_quoted_string
    assert_equal 'hello', host.extract_default("'hello'")
  end

  def test_extract_default_quoted_string_with_escaped_quote
    assert_equal "it's", host.extract_default("'it''s'")
  end

  def test_extract_default_boolean_true
    assert_equal 'true', host.extract_default('TRUE')
  end

  def test_extract_default_boolean_false
    assert_equal 'false', host.extract_default('FALSE')
  end

  def test_extract_default_integer
    assert_equal '42', host.extract_default('42')
  end

  def test_extract_default_negative_integer
    assert_equal '-7', host.extract_default('-7')
  end

  def test_extract_default_float
    assert_equal '3.14', host.extract_default('3.14')
  end

  def test_extract_default_sequence_returns_nil
    assert_nil host.extract_default('MY_SEQ.nextval')
  end

  def test_extract_default_unrecognised_returns_nil
    assert_nil host.extract_default('SOME_FUNCTION()')
  end

  # --- extract_data_type_from_snowflake ---

  def test_extract_data_type_number_maps_to_decimal
    assert_equal 'DECIMAL', host.extract_data_type('NUMBER')
  end

  def test_extract_data_type_timestamp_ltz_maps_to_timestamp
    assert_equal 'TIMESTAMP', host.extract_data_type('TIMESTAMP_LTZ')
  end

  def test_extract_data_type_timestamp_ntz_maps_to_timestamp
    assert_equal 'TIMESTAMP', host.extract_data_type('TIMESTAMP_NTZ')
  end

  def test_extract_data_type_text_maps_to_varchar
    assert_equal 'VARCHAR', host.extract_data_type('TEXT')
  end

  def test_extract_data_type_float_maps_to_double
    assert_equal 'DOUBLE', host.extract_data_type('FLOAT')
  end

  def test_extract_data_type_real_maps_to_double
    assert_equal 'DOUBLE', host.extract_data_type('REAL')
  end

  def test_extract_data_type_fixed_maps_to_decimal
    assert_equal 'DECIMAL', host.extract_data_type('FIXED')
  end

  def test_extract_data_type_passthrough_for_unknown
    assert_equal 'BOOLEAN', host.extract_data_type('BOOLEAN')
    assert_equal 'VARIANT', host.extract_data_type('VARIANT')
    assert_equal 'DATE',    host.extract_data_type('DATE')
  end

  # --- extract_column_size_from_snowflake ---

  def test_extract_column_size_timestamp_hardcoded
    assert_equal 35, host.extract_column_size('type' => 'TIMESTAMP_LTZ')
  end

  def test_extract_column_size_date_hardcoded
    assert_equal 10, host.extract_column_size('type' => 'DATE')
  end

  def test_extract_column_size_float_hardcoded
    assert_equal 38, host.extract_column_size('type' => 'FLOAT')
  end

  def test_extract_column_size_real_hardcoded
    assert_equal 38, host.extract_column_size('type' => 'REAL')
  end

  def test_extract_column_size_boolean_hardcoded
    assert_equal 1, host.extract_column_size('type' => 'BOOLEAN')
  end

  def test_extract_column_size_uses_length_for_varchar
    info = { 'type' => 'TEXT', 'length' => 255 }
    assert_equal 255, host.extract_column_size(info)
  end

  def test_extract_column_size_uses_precision_when_no_length
    info = { 'type' => 'NUMBER', 'precision' => 38 }
    assert_equal 38, host.extract_column_size(info)
  end

  def test_extract_column_size_returns_zero_when_no_size_info
    assert_equal 0, host.extract_column_size('type' => 'VARIANT')
  end

  # --- construct_sql_type ---

  def test_construct_sql_type_with_scale
    assert_equal 'DECIMAL(10,2)', host.build_sql_type('DECIMAL', 10, 2)
  end

  def test_construct_sql_type_with_limit_no_scale
    assert_equal 'VARCHAR(255)', host.build_sql_type('VARCHAR', 255, 0)
  end

  def test_construct_sql_type_no_limit_no_scale
    assert_equal 'BOOLEAN', host.build_sql_type('BOOLEAN', 0, 0)
  end

  # --- name_regex ---

  def test_name_regex_quoted_is_case_sensitive_exact
    regex = host.name_regex_for('"MySchema"')
    assert_match regex, 'MySchema'
    refute_match regex, 'myschema'
  end

  def test_name_regex_unquoted_is_case_insensitive
    regex = host.name_regex_for('MySchema')
    assert_match regex, 'MySchema'
    assert_match regex, 'myschema'
    assert_match regex, 'MYSCHEMA'
  end
end
