require 'unit_test_helper'
require 'odbc_adapter/database_statements'

class CaseFormattingHost
  include ODBCAdapter::DatabaseStatements

  def initialize(upcase_identifiers:)
    @upcase = upcase_identifiers
  end

  def database_metadata
    upcase = @upcase
    @meta ||= Struct.new(:upcase_identifiers?).new(upcase)
  end

  def prepared_statements = false

  # Expose private methods for testing
  def call_format_case(id)
    format_case(id)
  end

  def call_native_case(id)
    native_case(id)
  end
end

class CaseFormattingTest < Minitest::Test
  def upcase_host
    CaseFormattingHost.new(upcase_identifiers: true)
  end

  def normal_host
    CaseFormattingHost.new(upcase_identifiers: false)
  end

  # --- format_case (DB dict case → AR case) ---

  def test_format_case_upcase_all_caps_converts_to_lowercase
    assert_equal 'name', upcase_host.call_format_case('NAME')
  end

  def test_format_case_upcase_mixed_case_unchanged
    assert_equal 'camelCase', upcase_host.call_format_case('camelCase')
  end

  def test_format_case_upcase_lowercase_unchanged
    assert_equal 'name', upcase_host.call_format_case('name')
  end

  def test_format_case_no_upcase_returns_unchanged
    assert_equal 'NAME', normal_host.call_format_case('NAME')
    assert_equal 'name', normal_host.call_format_case('name')
    assert_equal 'camelCase', normal_host.call_format_case('camelCase')
  end

  # --- native_case (AR case → DB dict case) ---

  def test_native_case_upcase_all_lowercase_converts_to_uppercase
    assert_equal 'NAME', upcase_host.call_native_case('name')
  end

  def test_native_case_upcase_mixed_case_unchanged
    assert_equal 'camelCase', upcase_host.call_native_case('camelCase')
  end

  def test_native_case_upcase_already_uppercase_unchanged
    assert_equal 'NAME', upcase_host.call_native_case('NAME')
  end

  def test_native_case_no_upcase_returns_unchanged
    assert_equal 'name', normal_host.call_native_case('name')
    assert_equal 'NAME', normal_host.call_native_case('NAME')
  end
end
