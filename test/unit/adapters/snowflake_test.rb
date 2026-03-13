require 'unit_test_helper'
require 'odbc_adapter/adapters/snowflake_odbc_adapter'

class SnowflakeAdapterTest < Minitest::Test
  def adapter
    ODBCAdapter::Adapters::SnowflakeODBCAdapter.new
  end

  def test_primary_key_constant
    assert_equal 'INT PRIMARY KEY NOT NULL AUTOINCREMENT',
                 ODBCAdapter::Adapters::SnowflakeODBCAdapter::PRIMARY_KEY
  end

  def test_variant_type_constant
    assert_equal 'VARIANT', ODBCAdapter::Adapters::SnowflakeODBCAdapter::VARIANT_TYPE
  end

  def test_prepared_statements_is_false
    refute adapter.prepared_statements
  end

  def test_supports_migrations_is_false
    refute adapter.supports_migrations?
  end

  def test_inherits_from_odbc_adapter
    assert ODBCAdapter::Adapters::SnowflakeODBCAdapter.ancestors.include?(
      ActiveRecord::ConnectionAdapters::ODBCAdapter
    )
  end
end
