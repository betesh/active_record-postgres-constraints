# frozen_string_literal: true

source 'https://rubygems.org'

# Declare your gem's dependencies in active_record-postgres-constraints.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
gem 'byebug', '< 11.1.0', group: [:development, :test] # 11.1.0+ requires Ruby 2.4.0+

gem 'parallel_tests'
gem 'pg', '< 1.0' # Higher versions are not compatible with Rails 5.1

group :test do
  gem 'appraisal'
  gem 'simplecov', require: false
end

gem 'nio4r', '< 2.5.3' # To remain compatible with Ruby < 2.4
gem 'parallel', '< 1.20' # To remain compatible with Ruby < 2.4
gem 'simplecov-html', '< 0.11', require: false # To remain compatible with Ruby < 2.4
gem 'sprockets', '< 4' # To remain compatible with Ruby < 2.5
