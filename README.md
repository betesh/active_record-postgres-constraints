[![Gem Version](https://badge.fury.io/rb/active_record-postgres-constraints.svg)](https://badge.fury.io/rb/active_record-postgres-constraints)
[![Build Status](https://secure.travis-ci.org/on-site/active_record-postgres-constraints.svg?branch=master)](http://travis-ci.org/on-site/active_record-postgres-constraints)

# ActiveRecord::Postgres::Constraints

From http://edgeguides.rubyonrails.org/active_record_migrations.html#types-of-schema-dumps:

> There is however a trade-off: db/schema.rb cannot express database
specific items such as triggers, stored procedures or check constraints.
While in a migration you can execute custom SQL statements, the schema
dumper cannot reconstitute those statements from the database. If you are
using features like this, then you should set the schema format to :sql.

No longer is this the case.  You can now use the default schema format
(:ruby) and still preserve your check constraints.

At this time, this only supports check and exclude constraints for the postgresql ActiveRecord database adapter.

## Usage

#### Add a check constraint
Add check constraints to a table in a migration:

```ruby
create_table :people do |t|
  t.string :title
  t.check_constraint title: ['Mr.', 'Mrs.', 'Dr.']
end
```

OR

```ruby
add_check_constraint :people, title: ['Mr.', 'Mrs.', 'Dr.']
```

#### Remove a check constraint

```ruby
# If you don't need it to be reversible:
remove_check_constraint :people

# If you need it to be reversible (Recommended):
remove_check_constraint :people, title: ['Mr.', 'Mrs.', 'Dr.']
```

#### Add an exclude constraint
Add exclude constraints to a table in a migration:

```ruby
create_table :booking do |t|
  t.integer :room_id
  t.datetime :from
  t.datetime :to
  t.exclude_constraint using: :gist, 'tsrange("from", "to")' => :overlaps, room_id: :equals
end
```

OR

```ruby
add_exclude_constraint :booking, using: :gist, 'tsrange("from", "to")' => :overlaps, room_id: :equals
```

#### Remove an exclude constraint

```ruby
# If you don't need it to be reversible:
remove_exclude_constraint :booking

# If you need it to be reversible (Recommended):
remove_exclude_constraint :booking, using: :gist, 'tsrange("from", "to")' => :overlaps, room_id: :equals
```

#### Constrainsts with custom conditions

if you need custom/complex conditions of any sort, you can even use string conditions:

```ruby
create_table :people do |t|
  t.string :title
  t.check_constraint "title IS NULL OR title IN ['Mr.', 'Mrs.', 'Dr.']"
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'active_record-postgres-constraints'
```

And then execute:

```bash
$ bundle
```

## Testing
```bash
$ (cd spec/dummy && bin/rake db:create RAILS_ENV=test) # One time before running tests
$ bundle exec rspec # To run tests as often as you'd like
```

## Contributing
If you're interested in building support for other database adapters, we welcome your contribution!

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
