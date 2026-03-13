require 'unit_test_helper'
require 'odbc_adapter/adapters/mysql_odbc_adapter'

class MySQLAdapterTest < Minitest::Test
  def adapter
    ODBCAdapter::Adapters::MySQLODBCAdapter.new
  end

  def test_primary_key_constant
    assert_equal 'INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY',
                 ODBCAdapter::Adapters::MySQLODBCAdapter::PRIMARY_KEY
  end

  def test_prepared_statements_is_false
    refute adapter.prepared_statements
  end

  def test_quoted_true_is_one
    assert_equal '1', adapter.quoted_true
  end

  def test_quoted_false_is_zero
    assert_equal '0', adapter.quoted_false
  end

  def test_unquoted_true_is_integer_one
    assert_equal 1, adapter.unquoted_true
  end

  def test_unquoted_false_is_integer_zero
    assert_equal 0, adapter.unquoted_false
  end

  def test_quote_string_escapes_single_quotes
    assert_equal "it''s", adapter.quote_string("it's")
  end

  def test_quote_string_escapes_backslashes
    assert_equal 'back\\\\slash', adapter.quote_string('back\\slash')
  end

  def test_inherits_from_odbc_adapter
    assert ODBCAdapter::Adapters::MySQLODBCAdapter.ancestors.include?(
      ActiveRecord::ConnectionAdapters::ODBCAdapter
    )
  end
end
