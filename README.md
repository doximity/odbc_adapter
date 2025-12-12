# ODBCAdapter

[![Build Status](https://travis-ci.org/localytics/odbc_adapter.svg?branch=master)](https://travis-ci.org/localytics/odbc_adapter)
[![Gem](https://img.shields.io/gem/v/odbc_adapter.svg)](https://rubygems.org/gems/odbc_adapter)

An ActiveRecord ODBC adapter. Master branch is working off of Rails 5.0.1. Previous work has been done to make it compatible with Rails 3.2 and 4.2; for those versions use the 3.2.x or 4.2.x gem releases.

This adapter will work for basic queries for most DBMSs out of the box, without support for migrations. Full support is built-in for MySQL 5 and PostgreSQL 9 databases. You can register your own adapter to get more support for your DBMS using the `ODBCAdapter.register` function.

A lot of this work is based on [OpenLink's ActiveRecord adapter](http://odbc-rails.rubyforge.org/) which works for earlier versions of Rails.

## Installation

Ensure you have the ODBC driver installed on your machine. You will also need the driver for whichever database to which you want ODBC to connect.

Add this line to your application's Gemfile:

```ruby
gem 'odbc_adapter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install odbc_adapter

## Usage

Configure your `database.yml` by either using the `dsn` option to point to a DSN that corresponds to a valid entry in your `~/.odbc.ini` file:

```
development:
  adapter:  odbc
  dsn: MyDatabaseDSN
```

or by using the `conn_str` option and specifying the entire connection string:

```
development:
  adapter: odbc
  conn_str: "DRIVER={PostgreSQL ANSI};SERVER=localhost;PORT=5432;DATABASE=my_database;UID=postgres;"
```

ActiveRecord models that use this connection will now be connecting to the configured database using the ODBC driver.

## Testing

To run the tests, you'll need the ODBC driver as well as the connection adapter for each database against which you're trying to test. Then run `DSN=MyDatabaseDSN bundle exec rake test` and the test suite will be run by connecting to your database.

## Testing Using a Docker Container Because ODBC on Mac is Hard

Tested on Sierra.


Run from project root:

```
bundle package
docker build -f Dockerfile.dev -t odbc-dev .

# Local mount mysql directory to avoid some permissions problems
mkdir -p /tmp/mysql
docker run -it --rm -v $(pwd):/workspace -v /tmp/mysql:/var/lib/mysql odbc-dev:latest

# In container
docker/test.sh
```

## Releasing a New Version

To release a new version of the gem, follow these steps:

1. **Create a release branch**:
   ```bash
   git checkout -b release/vX.Y.Z
   ```

2. **Update the version number**:
   - Edit `lib/odbc_adapter/version.rb` and update the `VERSION` constant

3. **Update the CHANGELOG**:
   - Edit `CHANGELOG.md` to document all changes in this release
   - Update the release date for the version (use format `YYYY-MM-DD`)
   - Move any items from `[Unreleased]` to the new version section
   - Follow [Keep a Changelog](https://keepachangelog.com/) format

4. **Commit your changes**:
   ```bash
   git add lib/odbc_adapter/version.rb CHANGELOG.md
   git commit -m "Bump version to X.Y.Z"
   ```

5. **Push the branch and create a pull request**:
   ```bash
   git push origin release/vX.Y.Z
   ```
   - Create a PR to merge into `master`
   - Get it reviewed and approved

6. **After the PR is merged, tag the release**:
   ```bash
   git checkout master
   git pull
   git tag -a vX.Y.Z -m "Release version X.Y.Z"
   git push origin vX.Y.Z
   ```

7. **Build and publish the gem**:
   ```bash
   gem build odbc_adapter.gemspec
   gem push odbc_adapter-X.Y.Z.gem
   ```

8. **Create a GitHub release**:
   - Go to the [Releases page](https://github.com/doximity/odbc_adapter/releases)
   - Click "Draft a new release"
   - Select the tag you just created
   - Use the version number as the release title (e.g., `v7.0.0`)
   - Copy the relevant section from CHANGELOG.md into the release notes
   - Publish the release

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/localytics/odbc_adapter.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
