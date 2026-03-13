# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/database_statements'

class TrackingConnection
  attr_accessor :autocommit
  attr_reader :committed, :rolled_back

  def initialize
    @autocommit  = true
    @committed   = false
    @rolled_back = false
  end

  def commit
    @committed = true
  end

  def rollback
    @rolled_back = true
  end
end

class TransactionHost
  include ODBCAdapter::DatabaseStatements

  def database_metadata = nil
  def prepared_statements = false

  def initialize
    @raw_connection = TrackingConnection.new
  end

  def tracking_conn
    @raw_connection
  end
end

class TransactionTest < Minitest::Test
  def host
    TransactionHost.new
  end

  def test_begin_db_transaction_sets_autocommit_false
    h = host
    h.begin_db_transaction
    assert_equal false, h.tracking_conn.autocommit
  end

  def test_commit_db_transaction_calls_commit
    h = host
    h.commit_db_transaction
    assert_equal true, h.tracking_conn.committed
  end

  def test_commit_db_transaction_restores_autocommit_true
    h = host
    h.begin_db_transaction
    h.commit_db_transaction
    assert_equal true, h.tracking_conn.autocommit
  end

  def test_exec_rollback_db_transaction_calls_rollback
    h = host
    h.exec_rollback_db_transaction
    assert_equal true, h.tracking_conn.rolled_back
  end

  def test_exec_rollback_db_transaction_restores_autocommit_true
    h = host
    h.begin_db_transaction
    h.exec_rollback_db_transaction
    assert_equal true, h.tracking_conn.autocommit
  end
end
