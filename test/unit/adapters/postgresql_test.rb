# frozen_string_literal: true

require 'unit_test_helper'
require 'active_support/core_ext/hash/reverse_merge'
require 'odbc_adapter/adapters/postgresql_odbc_adapter'

class PostgreSQLAdapterTest < Minitest::Test
  def adapter
    ODBCAdapter::Adapters::PostgreSQLODBCAdapter.new
  end

  def test_primary_key_constant
    assert_equal 'SERIAL PRIMARY KEY',
                 ODBCAdapter::Adapters::PostgreSQLODBCAdapter::PRIMARY_KEY
  end

  def test_boolean_type_constant
    assert_equal 'boolean',
                 ODBCAdapter::Adapters::PostgreSQLODBCAdapter::BOOLEAN_TYPE
  end

  def test_quote_string_escapes_single_quotes
    assert_equal "it''s", adapter.quote_string("it's")
  end

  def test_quote_string_escapes_backslashes
    assert_equal 'back\\\\slash', adapter.quote_string('back\\slash')
  end

  def test_default_sequence_name_without_pk
    assert_equal 'users_id_seq', adapter.default_sequence_name('users')
  end

  def test_default_sequence_name_with_custom_pk
    assert_equal 'orders_order_id_seq', adapter.default_sequence_name('orders', 'order_id')
  end

  def test_inherits_from_odbc_adapter
    assert ODBCAdapter::Adapters::PostgreSQLODBCAdapter.ancestors.include?(
      ActiveRecord::ConnectionAdapters::ODBCAdapter
    )
  end

  # --- distinct ---

  def test_distinct_with_no_orders_returns_simple_distinct
    assert_equal 'DISTINCT posts.id', adapter.distinct('posts.id', [])
  end

  def test_distinct_strips_asc_modifier
    result = adapter.distinct('id', ['created_at DESC'])
    assert_includes result, 'created_at AS alias_0'
    refute_includes result, 'DESC'
  end

  def test_distinct_strips_asc_and_nulls_first
    result = adapter.distinct('id', ['name ASC NULLS FIRST'])
    refute_includes result, 'ASC'
    refute_includes result, 'NULLS'
  end

  def test_distinct_with_multiple_orders_generates_aliases
    result = adapter.distinct('id', ['col1 ASC', 'col2 DESC'])
    assert_includes result, 'alias_0'
    assert_includes result, 'alias_1'
  end

  # --- table_filtered? ---

  def test_table_filtered_rejects_information_schema
    assert adapter.table_filtered?('information_schema', 'TABLE')
  end

  def test_table_filtered_rejects_pg_catalog
    assert adapter.table_filtered?('pg_catalog', 'VIEW')
  end

  def test_table_filtered_rejects_non_table_type
    assert adapter.table_filtered?('public', 'INDEX')
  end

  def test_table_filtered_allows_regular_table
    refute adapter.table_filtered?('public', 'TABLE')
  end

  def test_table_filtered_allows_base_table
    refute adapter.table_filtered?('app_schema', 'BASE TABLE')
  end

  # --- type_cast ---

  def test_type_cast_bytea_string_wraps_in_format_hash
    col    = Struct.new(:native_type).new('bytea')
    result = adapter.type_cast('hello', col)
    assert_equal({ value: 'hello', format: 1 }, result)
  end

  # --- create_database ---

  def test_create_database_defaults_to_utf8_encoding
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb')
    assert_match(/ENCODING = 'utf8'/, sqls.first)
  end

  def test_create_database_with_owner
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb', owner: 'dbowner')
    assert_match(/OWNER = "dbowner"/, sqls.first)
  end

  def test_create_database_with_template
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb', template: 'template0')
    assert_match(/TEMPLATE = "template0"/, sqls.first)
  end

  def test_create_database_with_custom_encoding
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb', encoding: 'latin1')
    assert_match(/ENCODING = 'latin1'/, sqls.first)
  end

  def test_create_database_with_tablespace
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb', tablespace: 'pg_default')
    assert_match(/TABLESPACE = "pg_default"/, sqls.first)
  end

  def test_create_database_with_connection_limit
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb', connection_limit: 10)
    assert_match(/CONNECTION LIMIT = 10/, sqls.first)
  end

  def test_create_database_unknown_option_ignored
    a, sqls = pg_adapter_with_sql_capture
    a.create_database('mydb', unknown_key: 'val')
    refute_match(/unknown_key/, sqls.first)
  end

  # --- insert_sql ---

  def test_insert_sql_appends_returning_clause_when_pk_known
    a, selected = pg_adapter_for_insert_sql(pk_col: 'id')
    a.send(:insert_sql, 'INSERT INTO users (name) VALUES (?)', nil, nil)
    assert_match(/RETURNING "id"/, selected.first)
  end

  def test_insert_sql_uses_pk_when_provided_directly
    a = ODBCAdapter::Adapters::PostgreSQLODBCAdapter.new
    selected = []
    a.define_singleton_method(:select_value) do |sql, *|
      selected << sql
      1
    end
    a.define_singleton_method(:quote_column_name) { |col| "\"#{col}\"" }
    a.send(:insert_sql, 'INSERT INTO users VALUES (?)', nil, 'user_id')
    assert_match(/RETURNING "user_id"/, selected.first)
  end

  def test_insert_sql_select_value_returns_result
    a, _selected = pg_adapter_for_insert_sql(pk_col: 'id')
    result = a.send(:insert_sql, 'INSERT INTO users (name) VALUES (?)', nil, nil)
    assert_equal 42, result
  end

  private

  def pg_adapter_with_sql_capture
    a = ODBCAdapter::Adapters::PostgreSQLODBCAdapter.new
    sqls = []
    a.define_singleton_method(:execute) { |sql, *| sqls << sql }
    a.define_singleton_method(:quote_table_name) { |name| name }
    [a, sqls]
  end

  def pg_adapter_for_insert_sql(pk_col:)
    a = ODBCAdapter::Adapters::PostgreSQLODBCAdapter.new
    a.define_singleton_method(:extract_table_ref_from_insert_sql) { |_sql| 'users' }
    a.define_singleton_method(:primary_key) { |_table| pk_col }
    a.define_singleton_method(:quote_column_name) { |col| "\"#{col}\"" }
    selected = []
    a.define_singleton_method(:select_value) do |sql, *|
      selected << sql
      42
    end
    [a, selected]
  end
end
