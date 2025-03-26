lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'odbc_adapter/version'

Gem::Specification.new do |spec|
  spec.name          = 'odbc_adapter'
  spec.version       = ODBCAdapter::VERSION
  spec.authors       = ['Localytics']
  spec.email         = ['oss@localytics.com']

  spec.summary       = 'An ActiveRecord ODBC adapter'
  spec.homepage      = 'https://github.com/localytics/odbc_adapter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 7.1.2'
  spec.add_dependency 'ruby-odbc', '~> 0.99998'

  spec.add_development_dependency 'bundler', '>= 1.14'
  spec.add_development_dependency 'minitest', '~> 5.10'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '0.48.1'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'pry', '~> 0.11.1'

  spec.post_install_message = <<~MESSAGE
    == doximity/odbc_adapter ==

    If your project is already at or above Rails 7.2, and you are using the
    odbc_adapter to connect to Snowflake, please make sure to change the adapter
    name in your config/database.yml to snowflake_odbc.

    Example,

    snowflake_default: &snowflake_default
      adapter: snowflake_odbc
      conn_str: <%= ENV.fetch("SNOWFLAKE_CONNECTION", nil) %>

  MESSAGE
end
