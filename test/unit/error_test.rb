require 'unit_test_helper'
require 'odbc_adapter/error'

class ErrorTest < Minitest::Test
  def test_query_timeout_error_inherits_from_statement_invalid
    assert ODBCAdapter::QueryTimeoutError.ancestors.include?(ActiveRecord::StatementInvalid),
           'QueryTimeoutError must inherit from ActiveRecord::StatementInvalid'
  end

  def test_connection_failed_error_inherits_from_statement_invalid
    assert ODBCAdapter::ConnectionFailedError.ancestors.include?(ActiveRecord::StatementInvalid),
           'ConnectionFailedError must inherit from ActiveRecord::StatementInvalid'
  end

  def test_query_timeout_error_can_be_instantiated_with_message
    err = ODBCAdapter::QueryTimeoutError.new('query timed out')
    assert_equal 'query timed out', err.message
  end

  def test_connection_failed_error_can_be_instantiated_with_message
    err = ODBCAdapter::ConnectionFailedError.new('connection failed')
    assert_equal 'connection failed', err.message
  end

  def test_query_timeout_error_rescuable_as_statement_invalid
    raised = nil
    begin
      raise ODBCAdapter::QueryTimeoutError, 'timeout'
    rescue ActiveRecord::StatementInvalid => e
      raised = e
    end
    assert_instance_of ODBCAdapter::QueryTimeoutError, raised
  end

  def test_connection_failed_error_rescuable_as_statement_invalid
    raised = nil
    begin
      raise ODBCAdapter::ConnectionFailedError, 'failed'
    rescue ActiveRecord::StatementInvalid => e
      raised = e
    end
    assert_instance_of ODBCAdapter::ConnectionFailedError, raised
  end
end
