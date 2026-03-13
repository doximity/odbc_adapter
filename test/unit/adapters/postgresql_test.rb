# frozen_string_literal: true

require 'unit_test_helper'
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
end
