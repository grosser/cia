Audit model events like update/create/delete via an observer + attribute changes + all events grouped by a transaction.

```
Transaction (actor/ip/time/...)
 -> Event (updated subject + message)
   -> Change (changed password from foo to bar on subject)
```

 - actors and subjects are polymorphic
 - events come in different types like ActiveAuditing::UpdateEvent
 - transactions wrap multiple events, a nice place to add debugging info like source/action/ip

Install
=======
    gem install active_auditing
Or

    rails plugin install git://github.com/grosser/active_auditing.git


Usage
=====

```Ruby
class User < ActiveRecord::Base
  audited_attributes :email, :crypted_password
end

class ApplicationController < ActionController::Base
  around_filter :scope_auditing

  def scope_auditing
    Auditing.audit :actor => current_user, :ip_address => request.remote_ip do
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
[![Build Status](https://secure.travis-ci.org/grosser/active_auditing.png)](http://travis-ci.org/grosser/active_auditing)
