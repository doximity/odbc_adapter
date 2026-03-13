require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

# Integration tests — require a live ODBC connection
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/*_test.rb']
end

# Unit tests — no database connection required
Rake::TestTask.new('test:unit') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/unit/**/*_test.rb']
end

# Both integration and unit tests
Rake::TestTask.new('test:all') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new(:rubocop)
Rake::Task[:test].prerequisites << :rubocop

task default: :test
