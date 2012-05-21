Central Intelligent Auditing
============================

Audit model events like update/create/delete + attribute changes.

 - very normalized and queryable through table layout
 - actors and subjects are polymorphic
 - events come in different types like `CIA::UpdateEvent`
 - transactions wrap multiple events, a nice place to add debugging info like source/action/ip
 - works on ActiveRecord 2 and 3

Table layout:

    1 Transaction (actor/ip/time/...)
     -> has many events (updated subject + message)
      -> has many attribute changes (changed password from foo to bar on subject)


Install
=======
    gem install cia
Or

    rails plugin install git://github.com/grosser/cia.git

`rails g migration add_cia` + paste [Migration](https://raw.github.com/grosser/cia/master/Readme.md)


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
```


Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/cia.png)](http://travis-ci.org/grosser/cia)
