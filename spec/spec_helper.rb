$LOAD_PATH.unshift 'lib'
require 'cia'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define(:version => 1) do
  create_table :audit_transactions do |t|
    t.integer :actor_id, :null => false
    t.string :actor_type, :null => false
    t.string :ip_address
    t.timestamp :created_at
  end

  create_table :audit_events do |t|
    t.string :type, :source_type, :null => false
    t.integer :audit_transaction_id, :source_id, :null => false
    t.string :message
    t.timestamp :created_at
  end

  create_table :audit_attribute_changes do |t|
    t.integer :audit_event_id, :source_id, :null => false
    t.string :attribute_name, :source_type, :null => false
    t.string :old_value, :new_value
  end

  create_table :cars do |t|
    t.integer :wheels
    t.integer :drivers
    t.string :color
  end

  create_table :users do |t|
    t.string :email
  end
end

class User < ActiveRecord::Base
end

class Car < ActiveRecord::Base
  include CIA::Auditable
  audit_attribute :wheels
end

class CarWithAMessage < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels
  attr_accessor :audit_message
end

class CarWith3Attributes < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels, :color
  audit_attribute :drivers
end

class CarWithoutObservers < ActiveRecord::Base
  self.table_name = "cars"
end

class CarWithoutObservers2 < ActiveRecord::Base
  self.table_name = "cars"
end

def create_event
  transaction = CIA::Transaction.create!(:actor => User.create!)
  CIA::UpdateEvent.create!(:source => Car.create!, :transaction => transaction)
end

def create_change
  event = create_event
  CIA::AttributeChange.create!(:event => event, :source => event.source, :attribute_name => "bar")
end

module Rails
  def self.logger
    raise "NOT STUBBED"
  end

  def self.env
    @@env ||= "NOT STUBBED"
  end
end
