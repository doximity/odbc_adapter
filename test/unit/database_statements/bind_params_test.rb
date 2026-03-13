require 'unit_test_helper'
require 'odbc_adapter/database_statements'

class BindParamsHost
  include ODBCAdapter::DatabaseStatements

  def prepared_statements = true
  def database_metadata = nil

  # Expose private method
  def bind(binds, sql)
    # binds here are already-quoted strings (simulating prepared_binds output)
    bind_params(binds, sql)
  end

  private

  # Override prepared_binds to return the values as-is for test simplicity
  def prepared_binds(binds)
    binds
  end
end

class BindParamsTest < Minitest::Test
  def host
    BindParamsHost.new
  end

  def test_substitutes_single_bind
    sql    = 'SELECT * FROM users WHERE id = $1'
    result = host.bind(['42'], sql)
    assert_equal "SELECT * FROM users WHERE id = '42'", result
  end

  def test_substitutes_multiple_binds
    sql    = 'INSERT INTO t (a, b) VALUES ($1, $2)'
    result = host.bind(%w[foo bar], sql)
    assert_equal "INSERT INTO t (a, b) VALUES ('foo', 'bar')", result
  end

  def test_substitutes_in_order
    sql    = 'SELECT $1, $2, $1'
    result = host.bind(%w[a b], sql)
    # $1 replaced first, $2 replaced second — both $1 occurrences become 'a'
    assert_equal "SELECT 'a', 'b', 'a'", result
  end

  def test_no_binds_leaves_sql_unchanged
    sql    = 'SELECT * FROM users'
    result = host.bind([], sql)
    assert_equal sql, result
  end

  def test_bind_with_nil_value
    sql    = 'SELECT * FROM t WHERE x = $1'
    result = host.bind([nil], sql)
    assert_equal "SELECT * FROM t WHERE x = ''", result
  end
end
