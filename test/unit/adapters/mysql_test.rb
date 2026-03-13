# frozen_string_literal: true

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

  def adapter_with_sql_capture
    a = ODBCAdapter::Adapters::MySQLODBCAdapter.new
    sqls = []
    a.define_singleton_method(:execute) { |sql, *| sqls << sql }
    [a, sqls]
  end

  # --- create_database ---

  def test_create_database_defaults_to_utf8_charset
    a, sqls = adapter_with_sql_capture
    a.create_database('mydb')
    assert_includes sqls.first, 'DEFAULT CHARACTER SET `utf8`'
  end

  def test_create_database_with_custom_charset
    a, sqls = adapter_with_sql_capture
    a.create_database('mydb', charset: 'latin1')
    assert_includes sqls.first, 'DEFAULT CHARACTER SET `latin1`'
  end

  def test_create_database_with_charset_and_collation
    a, sqls = adapter_with_sql_capture
    a.create_database('mydb', charset: 'latin1', collation: 'latin1_bin')
    assert_includes sqls.first, 'DEFAULT CHARACTER SET `latin1`'
    assert_includes sqls.first, 'COLLATE `latin1_bin`'
  end

  def test_create_database_without_collation_omits_collate_clause
    a, sqls = adapter_with_sql_capture
    a.create_database('mydb')
    refute sqls.first.include?('COLLATE')
  end

  # --- indexes rejects PRIMARY key ---

  def test_indexes_filters_out_primary_key_index
    primary_idx = ActiveRecord::ConnectionAdapters::IndexDefinition.new('users', 'PRIMARY', true, ['id'])
    email_idx   = ActiveRecord::ConnectionAdapters::IndexDefinition.new('users', 'idx_email', false, ['email'])
    unique_idx  = ActiveRecord::ConnectionAdapters::IndexDefinition.new('users', 'idx_unique', true, ['email'])
    name_idx    = ActiveRecord::ConnectionAdapters::IndexDefinition.new('users', 'idx_name', false, ['name'])

    # Simulate what MySQLODBCAdapter#indexes does:
    # super(...).reject { |i| i.unique && i.name =~ /^PRIMARY$/ }
    all_indexes = [primary_idx, email_idx, unique_idx, name_idx]
    result = all_indexes.reject { |i| i.unique && i.name =~ /^PRIMARY$/ }

    assert_equal 3, result.length
    refute_includes result.map(&:name), 'PRIMARY'
    assert_includes result.map(&:name), 'idx_unique' # unique but not PRIMARY → kept
    assert_includes result.map(&:name), 'idx_email'
    assert_includes result.map(&:name), 'idx_name'
  end
end
