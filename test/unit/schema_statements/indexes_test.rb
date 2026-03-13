# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/schema_statements'
require 'odbc_adapter/database_statements'
require 'odbc_adapter/column'

class IndexSchemaHost
  include ODBCAdapter::SchemaStatements
  include ODBCAdapter::DatabaseStatements

  def initialize(rows)
    stmt = Struct.new(:rows) do
      def fetch_all = rows
      def drop = nil
    end.new(rows)

    @raw_connection = Struct.new(:stmt) do
      def indexes(_name) = stmt
    end.new(stmt)
  end

  def database_metadata
    @database_metadata ||= Struct.new(:upcase_identifiers?, :database_name).new(false, 'MYDB')
  end

  def current_database = 'MYDB'
  def current_schema = 'PUBLIC'
end

class IndexesSchemaTest < Minitest::Test
  # row[0]=db, row[1]=schema, row[3]=non_unique, row[5]=idx_name,
  # row[6]=type, row[7]=ordinal, row[8]=col_name
  def index_row(col_name:, idx_name: 'idx_users_email', ordinal: 1, **opts)
    non_unique = opts.fetch(:non_unique, 0)
    type       = opts.fetch(:type, 1)
    db         = opts.fetch(:db, 'MYDB')
    schema     = opts.fetch(:schema, 'PUBLIC')
    row = Array.new(10)
    row[0] = db
    row[1] = schema
    row[3] = non_unique
    row[5] = idx_name
    row[6] = type
    row[7] = ordinal
    row[8] = col_name
    row
  end

  def test_indexes_returns_empty_for_no_rows
    host = IndexSchemaHost.new([])
    assert_equal [], host.indexes('users')
  end

  def test_single_column_unique_index
    host = IndexSchemaHost.new([index_row(col_name: 'email', non_unique: 0)])
    result = host.indexes('users')
    assert result.first.unique
    assert_equal ['email'], result.first.columns
  end

  def test_single_column_non_unique_index
    host = IndexSchemaHost.new([index_row(col_name: 'email', non_unique: 1)])
    result = host.indexes('users')
    refute result.first.unique
  end

  def test_multi_column_index_groups_by_ordinal_position
    rows = [
      index_row(col_name: 'a', idx_name: 'idx', ordinal: 1, non_unique: 0),
      index_row(col_name: 'b', idx_name: 'idx', ordinal: 2, non_unique: 0)
    ]
    host = IndexSchemaHost.new(rows)
    result = host.indexes('users')
    assert_equal 1, result.length
    assert_equal %w[a b], result.first.columns
  end

  def test_skips_table_statistics_rows
    host = IndexSchemaHost.new([index_row(col_name: 'email', type: 0)])
    assert_equal [], host.indexes('users')
  end

  def test_skips_rows_with_wrong_db_name
    host = IndexSchemaHost.new([index_row(col_name: 'email', db: 'OTHER')])
    assert_equal [], host.indexes('users')
  end

  def test_index_name_is_correct
    host = IndexSchemaHost.new([index_row(col_name: 'email', idx_name: 'idx_users_email')])
    result = host.indexes('users')
    assert_equal 'idx_users_email', result.first.name
  end
end
