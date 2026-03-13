# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/schema_statements'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/column'

class ForeignKeySchemaHost
  include ODBCAdapter::SchemaStatements
  include ODBCAdapter::DatabaseStatements

  def initialize(rows)
    stmt = Struct.new(:rows) do
      def fetch_all = rows
      def drop = nil
    end.new(rows)

    @raw_connection = Struct.new(:stmt) do
      def foreign_keys(_name) = stmt
    end.new(stmt)
  end

  def database_metadata
    @database_metadata ||= Struct.new(:upcase_identifiers?, :database_name).new(false, 'MYDB')
  end

  def current_database = 'MYDB'
  def current_schema = 'PUBLIC'
end

class ForeignKeysSchemaTest < Minitest::Test
  # key[0]=db, key[1]=schema, key[2]=pktable, key[3]=pk_col,
  # key[6]=fktable, key[7]=fk_col, key[9]=update_rule, key[10]=delete_rule, key[11]=fk_name
  def fk_row(from_table: 'users', to_table: 'orders', pk_col: 'id', **opts)
    fk_col     = opts.fetch(:fk_col, 'user_id')
    fk_name    = opts.fetch(:fk_name, 'fk_orders_users')
    update_rule = opts.fetch(:update_rule, 0)
    delete_rule = opts.fetch(:delete_rule, 0)
    db         = opts.fetch(:db, 'MYDB')
    schema     = opts.fetch(:schema, 'PUBLIC')
    row = Array.new(12)
    row[0]  = db
    row[1]  = schema
    row[2]  = from_table
    row[3]  = pk_col
    row[6]  = to_table
    row[7]  = fk_col
    row[9]  = update_rule
    row[10] = delete_rule
    row[11] = fk_name
    row
  end

  def test_foreign_keys_empty_for_no_rows
    host = ForeignKeySchemaHost.new([])
    assert_equal [], host.foreign_keys('users')
  end

  def test_foreign_key_from_and_to_table
    host = ForeignKeySchemaHost.new([fk_row])
    fk = host.foreign_keys('users').first
    assert_equal 'users', fk.from_table
    assert_equal 'orders', fk.to_table
  end

  def test_foreign_key_name
    host = ForeignKeySchemaHost.new([fk_row])
    fk = host.foreign_keys('users').first
    assert_equal 'fk_orders_users', fk.name
  end

  def test_foreign_key_column_and_primary_key
    host = ForeignKeySchemaHost.new([fk_row(pk_col: 'id', fk_col: 'user_id')])
    fk = host.foreign_keys('users').first
    assert_equal 'id', fk.column
    assert_equal 'user_id', fk.primary_key
  end

  def test_skips_rows_with_wrong_db_schema
    # The source uses `next unless` inside map, which returns nil for skipped rows.
    host = ForeignKeySchemaHost.new([fk_row(db: 'WRONG')])
    result = host.foreign_keys('users')
    assert_equal 1, result.length
    assert_nil result.first
  end
end
