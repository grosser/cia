$LOAD_PATH.unshift 'lib'
require 'cia'

RSpec.configure do |config|
  config.before do
    CIA::Transaction.delete_all
    CIA::Event.delete_all
    CIA::AttributeChange.delete_all
  end
end

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define(:version => 1) do
  eval(File.read(File.expand_path('../../MIGRATION.rb', __FILE__)))

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

def create_change(options={})
  event = options.delete(:event) || create_event
  CIA::AttributeChange.create!({:event => event, :source => event.source, :attribute_name => "bar"}.merge(options))
end
