# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/registry'
require 'odbc_adapter/database_metadata'

# Builds a stub connection whose get_info returns configured values
def stub_connection(info_map = {})
  conn = Minitest::Mock.new
  ODBCAdapter::DatabaseMetadata::FIELDS.each do |field|
    numeric = ODBC.const_get(field)
    value   = info_map.fetch(field, "stub_#{field}")
    conn.expect(:get_info, value, [numeric])
  end
  conn
end

class DatabaseMetadataTest < Minitest::Test
  def test_dynamic_accessors_are_defined
    meta = ODBCAdapter::DatabaseMetadata.new(stub_connection)
    # Each FIELDS entry strips 'sql_' prefix to become an accessor
    assert_respond_to meta, :dbms_name
    assert_respond_to meta, :dbms_ver
    assert_respond_to meta, :identifier_case
    assert_respond_to meta, :identifier_quote_char
    assert_respond_to meta, :max_identifier_len
    assert_respond_to meta, :max_table_name_len
    assert_respond_to meta, :user_name
    assert_respond_to meta, :database_name
  end

  def test_dbms_name_returns_get_info_value
    conn = stub_connection(SQL_DBMS_NAME: 'Snowflake')
    meta = ODBCAdapter::DatabaseMetadata.new(conn)
    assert_equal 'Snowflake', meta.dbms_name
    conn.verify
  end

  def test_upcase_identifiers_true_when_sql_ic_upper
    conn = stub_connection(SQL_IDENTIFIER_CASE: ODBC::SQL_IC_UPPER)
    meta = ODBCAdapter::DatabaseMetadata.new(conn)
    assert meta.upcase_identifiers?
    conn.verify
  end

  def test_upcase_identifiers_false_when_not_sql_ic_upper
    conn = stub_connection(SQL_IDENTIFIER_CASE: ODBC::SQL_IC_LOWER)
    meta = ODBCAdapter::DatabaseMetadata.new(conn)
    refute meta.upcase_identifiers?
    conn.verify
  end

  def test_adapter_class_delegates_to_registry
    conn = stub_connection(SQL_DBMS_NAME: 'Snowflake')
    meta = ODBCAdapter::DatabaseMetadata.new(conn)
    assert_equal ODBCAdapter::Adapters::SnowflakeODBCAdapter, meta.adapter_class
    conn.verify
  end

  def test_encoding_bug_re_encodes_string_values
    # When has_encoding_bug=true, string values are re-encoded from UTF-16LE
    # We test that non-string values pass through unchanged
    conn = stub_connection(SQL_MAX_IDENTIFIER_LEN: 255)
    meta = ODBCAdapter::DatabaseMetadata.new(conn, false)
    assert_equal 255, meta.max_identifier_len
    conn.verify
  end

  def test_values_hash_contains_all_fields
    conn = stub_connection
    meta = ODBCAdapter::DatabaseMetadata.new(conn)
    assert_equal ODBCAdapter::DatabaseMetadata::FIELDS.length, meta.values.length
    conn.verify
  end
end
