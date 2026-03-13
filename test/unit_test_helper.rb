require 'simplecov'
SimpleCov.start do
  command_name 'Unit Tests'
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'active_record'
require 'minitest/autorun'

# ---------------------------------------------------------------------------
# ODBC stub — lets unit tests run without the ruby-odbc C extension.
# Values match the ODBC specification so tests can use the constants directly.
# ---------------------------------------------------------------------------
module ODBC
  # SQL data type codes
  SQL_CHAR             = 1
  SQL_NUMERIC          = 2
  SQL_DECIMAL          = 3
  SQL_INTEGER          = 4
  SQL_SMALLINT         = 5
  SQL_FLOAT            = 6
  SQL_REAL             = 7
  SQL_DOUBLE           = 8
  SQL_DATE             = 9
  SQL_TIME             = 10
  SQL_TIMESTAMP        = 11
  SQL_VARCHAR          = 12
  SQL_LONGVARCHAR      = -1
  SQL_BINARY           = -2
  SQL_VARBINARY        = -3
  SQL_LONGVARBINARY    = -4
  SQL_BIGINT           = -5
  SQL_TINYINT          = -6
  SQL_BIT              = -7
  SQL_DATETIME         = 9 # same numeric as SQL_DATE per ODBC spec
  SQL_TYPE_DATE        = 91
  SQL_TYPE_TIME        = 92
  SQL_TYPE_TIMESTAMP   = 93

  # Identifier case
  SQL_IC_UPPER         = 1
  SQL_IC_LOWER         = 2
  SQL_IC_SENSITIVE     = 3
  SQL_IC_MIXED         = 4

  # SQLGetInfo field codes (used by DatabaseMetadata)
  SQL_DBMS_NAME              = 17
  SQL_DBMS_VER               = 18
  SQL_IDENTIFIER_CASE        = 28
  SQL_QUOTED_IDENTIFIER_CASE = 93
  SQL_IDENTIFIER_QUOTE_CHAR  = 29
  SQL_MAX_IDENTIFIER_LEN     = 10_005
  SQL_MAX_TABLE_NAME_LEN     = 35
  SQL_USER_NAME              = 47
  SQL_DATABASE_NAME          = 16

  # Stub connection objects
  class Database
    def drvconnect(_driver) = StubConnection.new
  end

  class Driver
    attr_accessor :name, :attrs
  end

  # Minimal stub connection returned by ODBC.connect / Database#drvconnect
  class StubConnection
    def connected? = true
    def disconnect; end
    def use_time=(_val); end
    def get_info(_field) = 'stub'
    def autocommit=(_val); end
    def commit; end
    def rollback; end
  end

  class << self
    def connect(_dsn, _user, _pass)
      StubConnection.new
    end
  end
end

# ODBC_UTF8 is a UTF-8 variant; same stub for testing.
ODBC_UTF8 = ODBC unless defined?(ODBC_UTF8)

# ---------------------------------------------------------------------------
# Stub ODBCAdapter parent class so adapter subclasses can be loaded and
# instantiated without a real database connection.
# ---------------------------------------------------------------------------
module ActiveRecord
  module ConnectionAdapters
    class ODBCAdapter < AbstractAdapter
      attr_reader :database_metadata

      def initialize(*_args)
        # Skip the real connection setup
      end

      def supports_migrations?
        true
      end

      def prepared_statements
        true
      end
    end
  end
end
