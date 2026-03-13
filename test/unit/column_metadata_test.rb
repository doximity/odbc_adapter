# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/column_metadata'

class ColumnMetadataTest < Minitest::Test
  # native_type_mapping checks: `return adapter.class::PRIMARY_KEY if abstract == :primary_key`
  # The adapter class must have a PRIMARY_KEY constant.
  module FakeAdapterClass
    PRIMARY_KEY = 'INT PRIMARY KEY NOT NULL AUTOINCREMENT'
  end

  # Builds a fake adapter whose raw_connection.types() returns pre-canned rows.
  # SQLGetTypeInfo row format: [type_name, sql_type, col_size, ?, ?, create_params, ...]
  def make_adapter(type_rows)
    stmt = Struct.new(:rows) do
      def fetch_all = rows
      def drop = nil
    end.new(type_rows)

    raw_conn = Struct.new(:stmt) do
      def types = stmt
    end.new(stmt)

    # adapter.class must respond to ::PRIMARY_KEY
    adapter = Object.new
    adapter.instance_variable_set(:@raw_connection, raw_conn)
    adapter.define_singleton_method(:raw_connection) { @raw_connection }
    adapter.define_singleton_method(:class) { FakeAdapterClass }
    adapter
  end

  def test_native_database_types_maps_integer
    rows = [['INTEGER', ODBC::SQL_INTEGER, 10, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:integer), 'Expected :integer in native_database_types'
    assert_equal 'INTEGER', result[:integer][:name]
  end

  def test_native_database_types_maps_string_with_limit
    rows = [['VARCHAR', ODBC::SQL_VARCHAR, 255, nil, nil, 'length']]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:string)
    assert_equal 'VARCHAR', result[:string][:name]
    assert_equal 255, result[:string][:limit]
  end

  def test_native_database_types_text_picks_largest_capacity
    rows = [
      ['LONGVARCHAR', ODBC::SQL_LONGVARCHAR, 65_535, nil, nil, 'length'],
      ['VARCHAR',     ODBC::SQL_VARCHAR, 4096, nil, nil, 'length']
    ]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:text)
    assert_equal 'LONGVARCHAR', result[:text][:name]
  end

  def test_native_database_types_boolean_uses_available_candidate
    # boolean has SQL_BIT first, then SQL_TINYINT, SQL_SMALLINT, SQL_INTEGER
    rows = [['SMALLINT', ODBC::SQL_SMALLINT, 5, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:boolean)
    assert_equal 'SMALLINT', result[:boolean][:name]
  end

  def test_native_database_types_decimal_omits_limit
    rows = [['DECIMAL', ODBC::SQL_DECIMAL, 38, nil, nil, 'precision,scale']]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    # decimal explicitly excludes limit
    refute result[:decimal]&.key?(:limit)
  end

  def test_primary_key_returns_adapter_class_constant
    rows = [['INTEGER', ODBC::SQL_INTEGER, 10, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:primary_key)
    assert_equal 'INT PRIMARY KEY NOT NULL AUTOINCREMENT', result[:primary_key]
  end

  # --- additional type mappings ---

  def test_native_database_types_maps_float
    rows = [['DOUBLE', ODBC::SQL_DOUBLE, 15, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:float), 'Expected :float in native_database_types'
    assert_equal 'DOUBLE', result[:float][:name]
  end

  def test_native_database_types_maps_datetime
    rows = [['TIMESTAMP', ODBC::SQL_TYPE_TIMESTAMP, 26, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:datetime), 'Expected :datetime in native_database_types'
    assert_equal 'TIMESTAMP', result[:datetime][:name]
  end

  def test_native_database_types_maps_timestamp
    rows = [['TIMESTAMP', ODBC::SQL_TYPE_TIMESTAMP, 26, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:timestamp), 'Expected :timestamp in native_database_types'
    assert_equal 'TIMESTAMP', result[:timestamp][:name]
  end

  def test_native_database_types_maps_time
    rows = [['TIME', ODBC::SQL_TYPE_TIME, 8, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:time), 'Expected :time in native_database_types'
    assert_equal 'TIME', result[:time][:name]
  end

  def test_native_database_types_maps_date
    rows = [['DATE', ODBC::SQL_TYPE_DATE, 10, nil, nil, nil]]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:date), 'Expected :date in native_database_types'
    assert_equal 'DATE', result[:date][:name]
  end

  def test_native_database_types_binary_picks_largest_capacity
    rows = [
      ['LONGVARBINARY', ODBC::SQL_LONGVARBINARY, 2_147_483_647, nil, nil, nil],
      ['VARBINARY',     ODBC::SQL_VARBINARY,     8_000, nil, nil, nil]
    ]
    metadata = ODBCAdapter::ColumnMetadata.new(make_adapter(rows))
    result = metadata.native_database_types

    assert result.key?(:binary), 'Expected :binary in native_database_types'
    assert_equal 'LONGVARBINARY', result[:binary][:name]
  end
end
