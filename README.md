[![Build Status](https://secure.travis-ci.org/socialcast/delete_paranoid.png?branch=master)](http://travis-ci.org/socialcast/delete_paranoid)

# delete_paranoid

Soft Delete ActiveRecord instances.

## Usage

```ruby
class Blog < ActiveRecord::Base
  acts_as_paranoid
end
blog = Blog.create! :name => 'foo'

# soft delete the instance
blog.destroy

# query database for results *including* soft deleted objects
Blog.with_deleted do
  Blog.all
end

# permenantly delete the instance from the database
Blog.delete! blog.id
```

## Features
* simple configuration
* preserves existing ActiveRecord API.  No magical new API's to use when you want to soft delete a record
* automatically exclude soft deleted records from database queries (by default)
* support for querying database for all records (including soft deleted ones)
* support for permenantly deleting record from database

## Contributing

* Fork the project
* Fix the issue
* Add tests
* Submit a pull request on github

see CONTRIBUTORS.txt for complete list of contributors

## Copyright

Copyright (c) 2011 Socialcast Inc. 
See LICENSE.txt for further details.

