# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/database_statements'

class NullabilityHost
  include ODBCAdapter::DatabaseStatements

  def prepared_statements = false
  def database_metadata = nil

  # Expose private method
  def call_nullability(col_name, is_nullable, nullable)
    nullability(col_name, is_nullable, nullable)
  end
end

class NullabilityTest < Minitest::Test
  SQL_NO_NULLS = ODBCAdapter::DatabaseStatements::SQL_NO_NULLS
  SQL_NULLABLE = ODBCAdapter::DatabaseStatements::SQL_NULLABLE

  def host
    NullabilityHost.new
  end

  # MySQL hack: 'id' is always non-nullable regardless of reported value
  def test_id_column_always_non_nullable
    refute host.call_nullability('id', true, SQL_NULLABLE)
  end

  def test_id_column_always_non_nullable_even_when_nullable_true
    refute host.call_nullability('id', true, 'YES')
  end

  # SQL_NO_NULLS means not nullable
  def test_sql_no_nulls_returns_false
    refute host.call_nullability('name', true, SQL_NO_NULLS)
  end

  # SQL_NULLABLE means nullable
  def test_sql_nullable_returns_true
    assert host.call_nullability('name', true, SQL_NULLABLE)
  end

  # is_nullable=false means not nullable
  def test_is_nullable_false_returns_false
    refute host.call_nullability('name', false, SQL_NULLABLE)
  end

  # nullable string 'NO' means not nullable
  def test_nullable_string_no_returns_false
    refute host.call_nullability('name', true, 'NO')
  end

  # nullable string 'YES' means nullable
  def test_nullable_string_yes_returns_true
    assert host.call_nullability('name', true, 'YES')
  end

  # SQL_NULLABLE_UNKNOWN: assume nullable
  def test_sql_nullable_unknown_returns_true
    unknown = ODBCAdapter::DatabaseStatements::SQL_NULLABLE_UNKNOWN
    assert host.call_nullability('name', true, unknown)
  end
end
