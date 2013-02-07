destroyed_record_collector
==========================

Gem for collecting the deleted record for ActiveRecord to a new table named as (original_name_of_table)_backup in same database or       (original_name_of_table) in other database if other database configurations are provided in database.yml with ["#\{RUBY_ENV\}_backup"].