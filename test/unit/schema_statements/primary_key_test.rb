# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/schema_statements'
require 'odbc_adapter/database_statements'

class PrimaryKeySchemaHost
  include ODBCAdapter::SchemaStatements
  include ODBCAdapter::DatabaseStatements

  def initialize(rows)
    stmt = Struct.new(:rows) do
      def fetch_all = rows
      def drop = nil
    end.new(rows)

    @raw_connection = Struct.new(:stmt) do
      def primary_keys(_name) = stmt
    end.new(stmt)
  end

  def database_metadata
    @database_metadata ||= Struct.new(:upcase_identifiers?, :database_name).new(false, 'MYDB')
  end

  def current_database = 'MYDB'
  def current_schema = 'PUBLIC'
end

class PrimaryKeySchemaTest < Minitest::Test
  def pk_row(col_name:, db: 'MYDB', schema: 'PUBLIC', table: 'users')
    row = Array.new(5)
    row[0] = db
    row[1] = schema
    row[2] = table
    row[3] = col_name
    row
  end

  def test_primary_key_returns_nil_for_no_rows
    host = PrimaryKeySchemaHost.new([])
    assert_nil host.primary_key('users')
  end

  def test_primary_key_returns_column_name
    host = PrimaryKeySchemaHost.new([pk_row(col_name: 'id')])
    assert_equal 'id', host.primary_key('users')
  end

  def test_primary_key_filters_by_db_and_schema
    host = PrimaryKeySchemaHost.new([pk_row(col_name: 'id', db: 'WRONG')])
    assert_nil host.primary_key('users')
  end

  def test_primary_key_returns_last_match_when_multiple_rows
    rows = [
      pk_row(col_name: 'first_key'),
      pk_row(col_name: 'second_key')
    ]
    host = PrimaryKeySchemaHost.new(rows)
    assert_equal 'second_key', host.primary_key('users')
  end
end
