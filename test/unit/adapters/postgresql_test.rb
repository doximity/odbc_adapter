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
end
