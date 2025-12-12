# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [7.0.0] - TBD

### Added
- Rails 8.1 compatibility support
- Support for column initialization in both pre and post ActiveRecord 8.1.0
- Pass cast type to column for Rails 8.1 compatibility
- Define `write_query?` method for Rails 8.1 compatibility

### Changed
- Improved Rails 8.0 compatibility with `preprocess_query` method
- Extract preprocess handling to dedicated method
- Call `preprocess_query` if defined, fall back to `transform_query` for Rails 8 support
- Override schema fetching methods for tables and views to return empty arrays

### Removed
- Cleaned up unneeded wrapper method

## [6.0.2] - 2024

### Added
- Rails 8.1 compatibility support

### Changed
- Column initialization improvements for ActiveRecord 8.1.0

## [6.0.1] - 2024

### Fixed
- Fixed initializer for Rails < 7.2

## [6.0.0] - 2024

### Added
- Rails 7.2 compatibility support
- Post-install message for Snowflake adapter configuration
- Explicitly define `quote_table_name` for adapter (Rails 7.2 compatibility)
- Add `allow_retry` optional arg for Rails 7.2 compatibility
- Support registering adapter in ActiveRecord 7.2

### Changed
- Fetch tables only for the database and schema defined in the connection
- Make schema attribute lookup case insensitive
- Use SHOW TABLES query to address "size too big" errors for long table comments

### Fixed
- Guard against missing schema when querying for views
- Initialize known views to support checking for existence

## Earlier Versions

For changes in versions prior to 6.0.0, please see the git commit history.

[Unreleased]: https://github.com/doximity/odbc_adapter/compare/v7.0.0...HEAD
[7.0.0]: https://github.com/doximity/odbc_adapter/compare/v6.0.2...v7.0.0
[6.0.2]: https://github.com/doximity/odbc_adapter/compare/v6.0.1...v6.0.2
[6.0.1]: https://github.com/doximity/odbc_adapter/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/doximity/odbc_adapter/releases/tag/v6.0.0
