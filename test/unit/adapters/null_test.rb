require 'unit_test_helper'
require 'odbc_adapter/adapters/null_odbc_adapter'

class NullAdapterTest < Minitest::Test
  def adapter
    ODBCAdapter::Adapters::NullODBCAdapter.new
  end

  def test_prepared_statements_is_false
    refute adapter.prepared_statements
  end

  def test_supports_migrations_is_false
    refute adapter.supports_migrations?
  end

  def test_variant_type_constant
    assert_equal 'VARIANT', ODBCAdapter::Adapters::NullODBCAdapter::VARIANT_TYPE
  end

  def test_inherits_from_odbc_adapter
    assert ODBCAdapter::Adapters::NullODBCAdapter.ancestors.include?(
      ActiveRecord::ConnectionAdapters::ODBCAdapter
    )
  end
end
