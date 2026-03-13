# frozen_string_literal: true

require 'unit_test_helper'
require 'active_support/core_ext/date_time'
require 'odbc_adapter/type/internal/snowflake_variant'
require 'odbc_adapter/quoting'

# Minimal base quoting so Quoting#quote can call super for primitive values.
module BaseQuoting
  def quote(value)
    case value
    when String  then "'#{value.gsub("'", "''")}'"
    when Integer then value.to_s
    when Float   then value.to_s
    when NilClass then 'NULL'
    else "'#{value}'"
    end
  end
end

class QuotingHost
  include BaseQuoting
  include ODBCAdapter::Quoting

  def initialize(quote_char: '"', upcase: false)
    @quote_char = quote_char
    @upcase = upcase
  end

  def database_metadata
    upcase = @upcase
    qc     = @quote_char
    @database_metadata ||= Struct.new(:identifier_quote_char, :upcase_identifiers?).new(qc, upcase)
  end
end

class QuotingTest < Minitest::Test
  def host(quote_char: '"', upcase: false)
    QuotingHost.new(quote_char: quote_char, upcase: upcase)
  end

  # --- quote_string ---

  def test_quote_string_escapes_single_quotes
    assert_equal "it''s", host.quote_string("it's")
  end

  def test_quote_string_no_escaping_needed
    assert_equal 'hello', host.quote_string('hello')
  end

  def test_quote_string_multiple_quotes
    assert_equal "a''b''c", host.quote_string("a'b'c")
  end

  # --- quote_column_name ---

  def test_quote_column_name_wraps_in_quote_char
    assert_equal '"name"', host.quote_column_name('name')
  end

  def test_quote_column_name_already_quoted_passes_through
    assert_equal '"name"', host.quote_column_name('"name"')
  end

  def test_quote_column_name_no_quote_char_returns_plain
    assert_equal 'name', host(quote_char: '').quote_column_name('name')
  end

  def test_quote_column_name_upcase_pure_uppercase_passes_through
    assert_equal 'NAME', host(upcase: true).quote_column_name('NAME')
  end

  def test_quote_column_name_upcase_mixed_case_gets_quoted
    assert_equal '"camelCase"', host(upcase: true).quote_column_name('camelCase')
  end

  def test_quote_column_name_upcase_lowercase_passes_through
    assert_equal 'name', host(upcase: true).quote_column_name('name')
  end

  # --- quote_table_name ---

  def test_quote_table_name_delegates_to_quote_column_name
    assert_equal '"users"', host.quote_table_name('users')
  end

  # --- quote_hash ---

  def test_quote_hash_generates_object_construct
    result = host.quote_hash(hash: { 'key' => 'val' })
    assert_equal "OBJECT_CONSTRUCT('key','val')", result
  end

  def test_quote_hash_multiple_pairs
    result = host.quote_hash(hash: { 'a' => 1, 'b' => 2 })
    assert_equal "OBJECT_CONSTRUCT('a',1,'b',2)", result
  end

  def test_quote_hash_empty
    result = host.quote_hash(hash: {})
    assert_equal 'OBJECT_CONSTRUCT()', result
  end

  # --- quote_array ---

  def test_quote_array_generates_array_construct
    result = host.quote_array(array: %w[a b])
    assert_equal "ARRAY_CONSTRUCT('a','b')", result
  end

  def test_quote_array_empty
    result = host.quote_array(array: [])
    assert_equal 'ARRAY_CONSTRUCT()', result
  end

  # --- quote dispatch ---

  def test_quote_dispatches_hash_to_quote_hash
    result = host.quote({ 'k' => 'v' })
    assert_equal "OBJECT_CONSTRUCT('k','v')", result
  end

  def test_quote_dispatches_array_to_quote_array
    result = host.quote(['x'])
    assert_equal "ARRAY_CONSTRUCT('x')", result
  end

  def test_quote_dispatches_snowflake_variant
    sv = ODBCAdapter::Type::SnowflakeVariant.new('hello')
    result = host.quote(sv)
    assert_equal "'hello'::VARIANT", result
  end

  def test_quote_string_via_super
    result = host.quote('world')
    assert_equal "'world'", result
  end

  def test_quote_nil_via_super
    assert_equal 'NULL', host.quote(nil)
  end

  def test_quote_integer_via_super
    assert_equal '42', host.quote(42)
  end

  # --- quoted_date ---

  def test_quoted_date_formats_date
    assert_equal '2024-03-15', host.quoted_date(Date.new(2024, 3, 15))
  end

  def test_quoted_date_formats_time_as_datetime_string
    original_timezone = ActiveRecord.default_timezone
    ActiveRecord.default_timezone = :utc
    begin
      result = host.quoted_date(Time.utc(2024, 3, 15, 10, 30, 45))
      assert_equal '2024-03-15 10:30:45', result
    ensure
      ActiveRecord.default_timezone = original_timezone
    end
  end

  def test_quoted_date_formats_datetime
    result = host.quoted_date(DateTime.new(2024, 3, 15, 10, 30, 45))
    assert_match(/2024-03-15 10:30:45/, result)
  end
end
