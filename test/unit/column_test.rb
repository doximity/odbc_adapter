# frozen_string_literal: true

require 'unit_test_helper'
require 'odbc_adapter/column'

class ColumnTest < Minitest::Test
  # AR 8.1+ Column.new: (name, cast_type, default, sql_type_metadata, nullable, **)
  # AR <8.1:           (name, default, sql_type_metadata, nullable, **)
  # Deduplicable caches by (name, cast_type, default, sql_type_metadata, null) so
  # each test uses a unique name to avoid cross-test cache collisions.
  def build_column(name:, default: nil, sql_type: 'integer',
                   ar_type: ActiveRecord::Type::Integer.new, **col_opts)
    meta = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
      sql_type: sql_type, type: :integer, limit: nil, precision: nil, scale: nil
    )
    if ActiveRecord.version >= '8.1.0'
      ODBCAdapter::Column.new(name, ar_type, default, meta, true, **col_opts)
    else
      ODBCAdapter::Column.new(name, default, meta, true, **col_opts)
    end
  end

  def test_native_type_is_readable
    col = build_column(name: 'col_native_type_readable', native_type: 'DECIMAL')
    assert_equal 'DECIMAL', col.native_type
  end

  def test_native_type_defaults_to_nil
    col = build_column(name: 'col_native_type_default')
    assert_nil col.native_type
  end

  def test_auto_incremented_defaults_to_false
    col = build_column(name: 'col_auto_inc_default')
    refute col.auto_incremented
  end

  def test_auto_incremented_can_be_set_true
    col = build_column(name: 'col_auto_inc_true', auto_incremented: true)
    assert col.auto_incremented
  end

  def test_inherits_from_ar_column
    col = build_column(name: 'col_inherits')
    assert_kind_of ActiveRecord::ConnectionAdapters::Column, col
  end

  def test_name_is_set
    col = build_column(name: 'email_col')
    assert_equal 'email_col', col.name
  end
end
