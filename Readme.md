Central Internal Auditing
============================

Audit model actions like update/create/destroy/<custom> + attribute changes.

 - normalized and queryable through table layout
 - actors and subjects are polymorphic
 - works on ActiveRecord 4.2+

Table layout:

   Event (actor/ip/time/updated subject + message)
    -> has many attribute changes (changed password from foo to bar on subject)


Install
=======

```Bash
gem install cia
```

`rails g migration add_cia` + paste [Migration](https://raw.github.com/grosser/cia/master/MIGRATION.rb)

Then, create these two models in `app/models/cia`:

```ruby
# app/models/cia/event.rb

module CIA
  class Event < ActiveRecord::Base
    include EventMethods
  end
end
```

```ruby
# app/models/cia/attribute_change.rb

module CIA
  class AttributeChange < ActiveRecord::Base
    include AttributeChangeMethods
  end
end
```

If you’re using multiple databases, these models should inherit from an abstract class that specifies a database connection, not directly from ActiveRecord::Base.

Usage
=====

```Ruby
class User < ActiveRecord::Base
  include CIA::Auditable
  audit_attribute :email, :crypted_password
end

class ApplicationController < ActionController::Base
  around_action :scope_auditing

  def scope_auditing(&block)
    CIA.audit actor: current_user, ip_address: request.remote_ip, &block
  end
end

# quick access
User.last.cia_events
changes = User.last.cia_attribute_changes
last_passwords = changes.where(attribute_name: "crypted_password").map(&:new_value)

# exceptions (raised by default)
CIA.exception_handler = -> (e) { raise e unless Rails.env.production? }

# conditional auditing
class User < ActiveRecord::Base
  audit_attribute :email, if: :interesting?

  def interesting?
    ...
  end
end

# adding an actor e.g. for user creation
CIA.current_actor = @user

# custom changes
class User < ActiveRecord::Base
  def cia_changes
    super.merge("this" => ["always", "changes"])
  end
end

# using after_commit, useful if the CIA::Event is stored in a different database then the audited class
class User < ActiveRecord::Base
  include CIA::Auditable
  audit_attribute :email, :crypted_password, callback: :after_commit
end

# passing arbitrary attributes into the .audit method
CIA.non_recordable_attributes = [:my_pretty_audit_property]
CIA.audit(actor: current_user, my_pretty_audit_property: "12345") do
  ...
end

# storing complex objects in old/new and reducing it's size if it's to big (serialized via json)
value = CIA::AttributeChange.serialize_for_storage(["some", "complex"*1000, "object"]){|too_big| too_big.delete_at(1); too_big }
CIA::AttributeChange.create!(old_value: value)

# add something to current transaction or start a new audit
CIA.audit bar: :baz, foo: :bang do
  CIA.amend_audit foo: :bar do
    puts CIA.current_transaction
  end
end
-> {foo: :bar, bar: :baz}
```


# TODO
 - reuse AR3+ previous_changes in a nice way

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![CI](https://github.com/grosser/cia/actions/workflows/actions.yml/badge.svg)](https://github.com/grosser/cia/actions/workflows/actions.yml)
