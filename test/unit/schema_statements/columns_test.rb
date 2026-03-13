# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/schema_statements'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/column'

class ColumnsSchemaHost
  include ODBCAdapter::SchemaStatements
  include ODBCAdapter::DatabaseStatements

  def initialize(column_data)
    @column_data = column_data
  end

  def database_metadata
    @database_metadata ||= Struct.new(:upcase_identifiers?, :database_name).new(false, 'MYDB')
  end

  def current_database = 'MYDB'
  def current_schema = 'PUBLIC'

  # Stub to avoid needing a real type map — return a generic Value type.
  def lookup_cast_type_from_column(_meta)
    ActiveRecord::Type::Value.new
  end

  private

  def retrieve_column_data(_table_name)
    @column_data
  end
end

class ColumnsSchemaTest < Minitest::Test
  def col_data(column_name:, col_native_type:, **opts)
    { column_size: 0, numeric_scale: 0, col_default: nil, is_nullable: true,
      auto_incremented: false, column_name:, col_native_type: }.merge(opts)
  end

  def columns_for(data)
    ColumnsSchemaHost.new([data]).columns('users')
  end

  def test_columns_varchar_type
    col = columns_for(col_data(column_name: 'email', col_native_type: 'VARCHAR', column_size: 255)).first
    assert_equal :string, col.type
    assert_equal 'VARCHAR(255)', col.sql_type
  end

  def test_columns_boolean_type
    col = columns_for(col_data(column_name: 'active', col_native_type: 'BOOLEAN')).first
    assert_equal :boolean, col.type
  end

  def test_columns_variant_type
    col = columns_for(col_data(column_name: 'payload', col_native_type: 'VARIANT')).first
    assert_equal :variant, col.type
  end

  def test_columns_date_type
    col = columns_for(col_data(column_name: 'dob', col_native_type: 'DATE')).first
    assert_equal :date, col.type
  end

  def test_columns_timestamp_type
    col = columns_for(col_data(column_name: 'created_at', col_native_type: 'TIMESTAMP')).first
    assert_equal :datetime, col.type
  end

  def test_columns_time_type
    col = columns_for(col_data(column_name: 'start_time', col_native_type: 'TIME')).first
    assert_equal :time, col.type
  end

  def test_columns_binary_type
    col = columns_for(col_data(column_name: 'data', col_native_type: 'BINARY')).first
    assert_equal :binary, col.type
  end

  def test_columns_double_type
    col = columns_for(col_data(column_name: 'score', col_native_type: 'DOUBLE')).first
    assert_equal :float, col.type
  end

  def test_columns_decimal_scale_zero_type
    col = columns_for(col_data(column_name: 'count', col_native_type: 'DECIMAL', numeric_scale: 0)).first
    assert_equal :integer, col.type
  end

  def test_columns_decimal_with_scale_type
    col = columns_for(
      col_data(column_name: 'amount', col_native_type: 'DECIMAL', column_size: 10, numeric_scale: 2)
    ).first
    assert_equal :decimal, col.type
  end

  def test_columns_auto_incremented_flag
    col = columns_for(
      col_data(column_name: 'id_auto_inc', col_native_type: 'DECIMAL', auto_incremented: true)
    ).first
    assert col.auto_incremented
  end

  def test_columns_native_type_preserved
    col = columns_for(col_data(column_name: 'email', col_native_type: 'VARCHAR', column_size: 100)).first
    assert_equal 'VARCHAR', col.native_type
  end

  def test_columns_nullable_flag
    col = columns_for(
      col_data(column_name: 'required_field', col_native_type: 'VARCHAR', is_nullable: false)
    ).first
    assert_equal false, col.null
  end

  def test_columns_returns_multiple_columns
    host = ColumnsSchemaHost.new([
                                   col_data(column_name: 'id', col_native_type: 'DECIMAL'),
                                   col_data(column_name: 'email', col_native_type: 'VARCHAR', column_size: 255)
                                 ])
    assert_equal 2, host.columns('users').length
  end

  def test_columns_unknown_type_maps_to_nil_type
    # An unrecognised native type falls through to the else branch and returns nil.
    # The columns method should not raise.
    col = columns_for(col_data(column_name: 'mystery', col_native_type: 'UNKNOWN_SF_TYPE')).first
    assert_nil col.type
  end

  # --- STRUCT and ARRAY types ---

  def test_columns_struct_maps_to_object_type
    col = columns_for(col_data(column_name: 'meta', col_native_type: 'STRUCT')).first
    assert_equal :object, col.type
  end

  def test_columns_array_maps_to_array_type
    col = columns_for(col_data(column_name: 'tags', col_native_type: 'ARRAY')).first
    assert_equal :array, col.type
  end

  # --- extract_scale_from_snowflake ---

  def test_extract_scale_from_snowflake_uses_scale_key
    col = columns_for(
      col_data(column_name: 'price', col_native_type: 'DECIMAL', column_size: 10, numeric_scale: 3)
    ).first
    assert_equal 'DECIMAL(10,3)', col.sql_type
  end

  def test_extract_scale_from_snowflake_defaults_to_zero_when_absent
    col = columns_for(
      col_data(column_name: 'count', col_native_type: 'DECIMAL', column_size: 0, numeric_scale: 0)
    ).first
    assert_equal :integer, col.type
  end
end
