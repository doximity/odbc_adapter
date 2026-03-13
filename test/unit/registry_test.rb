# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/registry'

class RegistryUnitTest < Minitest::Test
  def registry
    ODBCAdapter::Registry.new
  end

  def test_mysql_pattern_resolves_to_mysql_adapter
    adapter = registry.adapter_for('MySQL')
    assert_equal ODBCAdapter::Adapters::MySQLODBCAdapter, adapter
  end

  def test_mysql_pattern_is_case_insensitive
    assert_equal ODBCAdapter::Adapters::MySQLODBCAdapter, registry.adapter_for('mysql')
    assert_equal ODBCAdapter::Adapters::MySQLODBCAdapter, registry.adapter_for('MYSQL')
  end

  def test_mysql_pattern_matches_partial_name
    assert_equal ODBCAdapter::Adapters::MySQLODBCAdapter, registry.adapter_for('mysql57')
  end

  def test_postgres_pattern_resolves_to_postgresql_adapter
    adapter = registry.adapter_for('PostgreSQL')
    assert_equal ODBCAdapter::Adapters::PostgreSQLODBCAdapter, adapter
  end

  def test_snowflake_pattern_resolves_to_snowflake_adapter
    adapter = registry.adapter_for('Snowflake')
    assert_equal ODBCAdapter::Adapters::SnowflakeODBCAdapter, adapter
  end

  def test_snowflake_with_whitespace_stripped
    # adapter_for lowercases and strips spaces before matching
    adapter = registry.adapter_for('Snow Flake')
    assert_equal ODBCAdapter::Adapters::SnowflakeODBCAdapter, adapter
  end

  def test_unknown_name_resolves_to_null_adapter
    adapter = registry.adapter_for('SomeUnknownDatabase')
    assert_equal ODBCAdapter::Adapters::NullODBCAdapter, adapter
  end

  def test_empty_string_resolves_to_null_adapter
    adapter = registry.adapter_for('')
    assert_equal ODBCAdapter::Adapters::NullODBCAdapter, adapter
  end

  def test_custom_registration_with_block
    r = registry
    r.register(/foobar/i) {}
    adapter = r.adapter_for('FooBar DB')
    assert_kind_of Class, adapter
  end

  def test_custom_registration_with_superclass
    r = registry
    r.register(/custom/i, ODBCAdapter::Adapters::MySQLODBCAdapter)
    adapter = r.adapter_for('custom db')
    assert adapter.ancestors.include?(ODBCAdapter::Adapters::MySQLODBCAdapter)
  end

  def test_adapter_for_class_method_delegates_to_registry
    adapter = ODBCAdapter.adapter_for('Snowflake')
    assert_equal ODBCAdapter::Adapters::SnowflakeODBCAdapter, adapter
  end
end
