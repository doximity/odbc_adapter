module ODBCAdapter
  class Column < ActiveRecord::ConnectionAdapters::Column
    attr_reader :native_type, :auto_incremented

    # Add the native_type accessor to allow the native DBMS to report back what
    # it uses to represent the column internally.
    # rubocop:disable Metrics/ParameterLists
    def initialize(*, native_type: nil, auto_incremented: false, **)
      super

      @native_type = native_type
      @auto_incremented = auto_incremented
    end
  end
end
