# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/database_limits'

class DatabaseLimitsHost
  include ODBCAdapter::DatabaseLimits

  def initialize(max_identifier_len:, max_table_name_len:)
    @meta = Struct.new(:max_identifier_len, :max_table_name_len)
                  .new(max_identifier_len, max_table_name_len)
  end

  def database_metadata
    @meta
  end
end

class DatabaseLimitsTest < Minitest::Test
  def test_table_alias_length_returns_max_identifier_len_when_larger
    host = DatabaseLimitsHost.new(max_identifier_len: 256, max_table_name_len: 128)
    assert_equal 256, host.table_alias_length
  end

  def test_table_alias_length_returns_max_table_name_len_when_larger
    host = DatabaseLimitsHost.new(max_identifier_len: 64, max_table_name_len: 128)
    assert_equal 128, host.table_alias_length
  end

  def test_table_alias_length_returns_equal_value_when_same
    host = DatabaseLimitsHost.new(max_identifier_len: 100, max_table_name_len: 100)
    assert_equal 100, host.table_alias_length
  end
end
