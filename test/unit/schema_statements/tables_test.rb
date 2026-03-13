# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/schema_statements'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/column'

class TablesSchemaHost
  include ODBCAdapter::SchemaStatements
  include ODBCAdapter::DatabaseStatements

  def initialize(rows, db: 'MYDB', schema: 'PUBLIC', upcase_identifiers: false)
    @db = db
    @schema = schema
    @upcase_identifiers = upcase_identifiers

    each_hash_rows = rows
    execute_result = Object.new
    execute_result.define_singleton_method(:each_hash) do |&blk|
      each_hash_rows.each { |r| blk.call(r) }
    end

    stmt = Object.new
    stmt.define_singleton_method(:execute) { execute_result }
    stmt.define_singleton_method(:drop) {}

    @raw_connection = Object.new
    @raw_connection.define_singleton_method(:prepare) { |_sql| stmt }
  end

  def database_metadata
    upcase = @upcase_identifiers
    @database_metadata ||= Struct.new(:upcase_identifiers?, :database_name).new(upcase, @db)
  end

  def current_database = @db
  def current_schema = @schema
end

class TablesSchemaTest < Minitest::Test
  def table_row(name:, db: 'MYDB', schema: 'PUBLIC', kind: 'TABLE')
    { 'name' => name, 'database_name' => db, 'schema_name' => schema, 'kind' => kind }
  end

  def test_tables_returns_empty_for_no_rows
    host = TablesSchemaHost.new([])
    assert_equal [], host.tables
  end

  def test_tables_returns_table_names
    host = TablesSchemaHost.new([table_row(name: 'users')])
    assert_equal ['users'], host.tables
  end

  def test_tables_returns_multiple_tables
    host = TablesSchemaHost.new([
                                  table_row(name: 'users'),
                                  table_row(name: 'orders')
                                ])
    assert_equal %w[users orders], host.tables
  end

  def test_tables_filters_wrong_database
    host = TablesSchemaHost.new([
                                  table_row(name: 'users', db: 'OTHER'),
                                  table_row(name: 'orders')
                                ])
    assert_equal ['orders'], host.tables
  end

  def test_tables_filters_wrong_schema
    host = TablesSchemaHost.new([
                                  table_row(name: 'users', schema: 'OTHER'),
                                  table_row(name: 'orders')
                                ])
    assert_equal ['orders'], host.tables
  end

  def test_tables_calls_table_filtered_if_present
    host = TablesSchemaHost.new([table_row(name: 'users', kind: 'TABLE')])
    # Extend with table_filtered? that excludes TABLE kind rows.
    host.define_singleton_method(:table_filtered?) { |_schema, kind| kind == 'TABLE' }
    assert_equal [], host.tables
  end

  def test_tables_applies_format_case
    # With upcase_identifiers?: true, an all-caps name from the DB is downcased.
    host = TablesSchemaHost.new([table_row(name: 'USERS')], upcase_identifiers: true)
    assert_equal ['users'], host.tables
  end
end
