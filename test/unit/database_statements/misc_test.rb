# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/database_statements'

class MiscStatementsHost
  include ODBCAdapter::DatabaseStatements

  def database_metadata = nil
  def prepared_statements = false
end

class MiscDatabaseStatementsTest < Minitest::Test
  def host
    MiscStatementsHost.new
  end

  # --- write_query? ---

  def test_write_query_true_for_insert
    assert_equal true, host.write_query?('INSERT INTO t VALUES (1)')
  end

  def test_write_query_true_for_update
    assert_equal true, host.write_query?('UPDATE t SET x=1')
  end

  def test_write_query_false_for_show
    assert_equal false, host.write_query?('SHOW TABLES')
  end

  def test_write_query_false_for_set
    assert_equal false, host.write_query?('SET x = 1')
  end

  def test_write_query_handles_invalid_encoding_gracefully
    bad_sql = "SELECT \xFF\xFE".dup.force_encoding('UTF-8')
    result = host.write_query?(bad_sql)
    assert_includes [true, false], result
  end

  # --- default_sequence_name ---

  def test_default_sequence_name
    assert_equal 'users_seq', host.default_sequence_name('users', 'id')
  end

  def test_default_sequence_name_ignores_column
    assert_equal 'orders_seq', host.default_sequence_name('orders', 'order_id')
  end

  # --- empty_insert_statement_value ---

  def test_empty_insert_statement_value_with_pk
    assert_equal '(id) VALUES (DEFAULT)', host.empty_insert_statement_value('id')
  end

  def test_empty_insert_statement_value_with_nil
    assert_equal '() VALUES (DEFAULT)', host.empty_insert_statement_value
  end

  # --- handle_query_preprocessing ---

  def test_handle_query_preprocessing_calls_preprocess_query_when_available
    h = host
    called_with = nil
    h.define_singleton_method(:preprocess_query) do |sql|
      called_with = sql
      sql
    end
    h.send(:handle_query_preprocessing, 'SELECT 1')
    assert_equal 'SELECT 1', called_with
  end

  def test_handle_query_preprocessing_falls_back_to_transform_query
    h = host
    called_with = nil
    h.define_singleton_method(:transform_query) do |sql|
      called_with = sql
      sql
    end
    h.send(:handle_query_preprocessing, 'SELECT 2')
    assert_equal 'SELECT 2', called_with
  end
end
