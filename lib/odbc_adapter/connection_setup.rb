module ODBCAdapter
  class ConnectionSetup
    attr_reader :config
    attr_reader :connection

    def initialize(config)
      @config = config
      @connection = nil
    end

    def build
      if @config.key?(:dsn)
        odbc_dsn_connection
      elsif @config.key?(:conn_str)
        odbc_conn_str_connection
      else
        raise ArgumentError, 'No data source name (:dsn) or connection string (:conn_str) specified.'
      end
    end

    private

    # Connect using a predefined DSN.
    def odbc_dsn_connection
      username   = @config[:username] ? @config[:username].to_s : nil
      password   = @config[:password] ? @config[:password].to_s : nil
      odbc_module = @config[:encoding] == 'utf8' ? ODBC_UTF8 : ODBC

      @connection = odbc_module.connect(@config[:dsn], username, password)
      # encoding_bug indicates that the driver is using non ASCII and has the issue referenced here https://github.com/larskanis/ruby-odbc/issues/2
      @config.merge!(username: username, password: password, encoding_bug: @config[:encoding] == 'utf8')
    end

    # Connect using ODBC connection string
    # Supports DSN-based or DSN-less connections
    # e.g. "DSN=virt5;UID=rails;PWD=rails"
    #      "DRIVER={OpenLink Virtuoso};HOST=carlmbp;UID=rails;PWD=rails"
    def odbc_conn_str_connection
      attrs = @config[:conn_str].split(';').map { |option| option.split('=', 2) }.to_h
      odbc_module = attrs['ENCODING'] == 'utf8' ? ODBC_UTF8 : ODBC
      driver = odbc_module::Driver.new
      driver.name = 'odbc'
      driver.attrs = attrs

      @connection = odbc_module::Database.new.drvconnect(driver)
      # encoding_bug indicates that the driver is using non ASCII and has the issue referenced here https://github.com/larskanis/ruby-odbc/issues/2
      @config.merge!(driver: driver, encoding: attrs['ENCODING'], encoding_bug: attrs['ENCODING'] == 'utf8')
    end
  end
end
