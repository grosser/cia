Central Internal Auditing
============================

Audit model actions like update/create/destroy/<custom> + attribute changes.

 - normalized and queryable through table layout
 - actors and subjects are polymorphic
 - works on ActiveRecord 2 and 3

Table layout:

   Event (actor/ip/time/updated subject + message)
    -> has many attribute changes (changed password from foo to bar on subject)


Install
=======
    gem install cia
Or

    rails plugin install git://github.com/grosser/cia.git

`rails g migration add_cia` + paste [Migration](https://raw.github.com/grosser/cia/master/MIGRATION.rb)


Usage
=====

```Ruby
class User < ActiveRecord::Base
  include CIA::Auditable
  audited_attributes :email, :crypted_password
end

class ApplicationController < ActionController::Base
  around_filter :scope_auditing

  def scope_auditing
    CIA.audit :actor => current_user, :ip_address => request.remote_ip do
      yield
    end
  end
end

# quick access
User.last.cia_events
changes = User.last.cia_attribute_changes
last_passwords = changes.where(:attribute_name => "crypted_password").map(&:new_value)

# exceptions (raised by default)
CIA.exception_handler = lambda{|e| raise e unless Rails.env.production? }

# conditional auditing
class User < ActiveRecord::Base
  audited_attributes :email, :if => :interesting?

  def interesting?
    ...
  end
end

# adding an actor e.g. for user creation
CIA.current_actor = @user

# custom changes

class User < ActiveRecord::Base
  def cia_changes
    changes.merge("this" => ["always", "changes"])
  end
end
```


Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/cia.png)](http://travis-ci.org/grosser/cia)
