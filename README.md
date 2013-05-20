# Destroyed Record Collector

Gem for collecting the deleted record for ActiveRecord to a new table named as (original_name_of_table)_backup in same database or (original_name_of_table) in other database if other database configurations are provided in database.yml with ["#\{RUBY_ENV\}_backup"].

## Installation

Add to `Gemfile` run `bundle install`:

```ruby
# Gemfile
gem 'destroyed_record_collector'
```

# Usage

if data is to be backed up in the same database then nothing is to be provided (table will be created with model_name_backup)
else if data is to be backed up in different database then define a new setting in config/database.yml (table will be created as of same table name)
the name should be "#\{RUBY_ENV\}_backup"

```ruby
development_backup:
  adapter: mysql2
  encoding: utf8
  database: destroyed_development
  pool: 5
  username: username
  password: password
  socket: /var/run/mysqld/mysqld.sock
```

it will create backup for all models and if some models are needed to exclude from backup should have a method 'exclude_from_backup'
which will return true. Else all models will have a backup table.

```ruby
def exclude_from_backup
return true //if backup is not needed
end
```