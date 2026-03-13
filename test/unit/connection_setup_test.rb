# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/connection_setup'

class ConnectionSetupTest < Minitest::Test
  # --- error case ---

  def test_raises_on_missing_dsn_and_conn_str
    setup = ODBCAdapter::ConnectionSetup.new({ adapter: 'odbc' })
    assert_raises(ArgumentError) { setup.build }
  end

  # --- DSN path ---

  def test_dsn_stores_connection_object
    config = { dsn: 'MyDSN', username: 'user', password: 'pass' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert_instance_of ODBC::StubConnection, setup.connection
  end

  def test_dsn_stores_encoding_bug_false_without_utf8
    config = { dsn: 'MyDSN' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    refute setup.config[:encoding_bug]
  end

  def test_dsn_stores_encoding_bug_true_with_utf8_encoding
    config = { dsn: 'MyDSN', encoding: 'utf8' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert setup.config[:encoding_bug]
  end

  def test_dsn_normalizes_nil_username_to_nil
    config = { dsn: 'MyDSN' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert_nil setup.config[:username]
  end

  def test_dsn_converts_symbol_username_to_string
    config = { dsn: 'MyDSN', username: :admin }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert_equal 'admin', setup.config[:username]
  end

  def test_connection_is_nil_before_build
    config = { dsn: 'MyDSN' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    assert_nil setup.connection
  end

  def test_connection_is_set_after_build
    config = { dsn: 'MyDSN' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    refute_nil setup.connection
  end

  # --- connection string path ---

  def test_conn_str_stores_connection_object
    config = { conn_str: 'DRIVER=Snowflake;UID=user;PWD=secret' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert_instance_of ODBC::StubConnection, setup.connection
  end

  def test_conn_str_stores_driver_in_config
    config = { conn_str: 'DRIVER=Snowflake;UID=user' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert_instance_of ODBC::Driver, setup.config[:driver]
  end

  def test_conn_str_encoding_bug_false_without_utf8
    config = { conn_str: 'DRIVER=Snowflake;UID=user' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    refute setup.config[:encoding_bug]
  end

  def test_conn_str_encoding_bug_true_with_utf8_encoding
    config = { conn_str: 'DRIVER=Snowflake;ENCODING=utf8' }
    setup  = ODBCAdapter::ConnectionSetup.new(config)
    setup.build
    assert setup.config[:encoding_bug]
  end
end
