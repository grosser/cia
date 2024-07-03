require 'cia'

I18n.enforce_available_locales = false

if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 2
  ActiveRecord::Base.raise_in_transactional_callbacks = true
end

module CIA
  class Event < ActiveRecord::Base
    include EventMethods
  end

  class AttributeChange < ActiveRecord::Base
    include AttributeChangeMethods
  end
end

RSpec.configure do |config|
  config.before do
    CIA::Event.delete_all
    CIA::AttributeChange.delete_all
    CIA.non_recordable_attributes = nil
  end
end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(version: 1) do
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
  audit_attribute :wheels, :color, :drivers
end

class CarWithIf < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels, if: :tested
  attr_accessor :tested
end

class CarWithUnless < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels, unless: :tested
  attr_accessor :tested
end

class CarWithCustomChanges < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels, :foo

  def cia_changes
    super.merge("foo" => ["bar", "baz"])
  end
end

class FailCar < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels

  class Oops < Exception
  end

  after_update { |x| raise Oops }
  after_create { |x| raise Oops }
  after_destroy { |x| raise Oops }
end

class CarWithTransactions < ActiveRecord::Base
  self.table_name = "cars"
  include CIA::Auditable
  audit_attribute :wheels, :drivers, callback: :after_commit
end

class NestedCar < Car
  audit_attribute :drivers
end

class InheritedCar < Car
end

def create_event(options={})
  CIA::Event.create!({source: Car.create!, actor: User.create!, action: "update"}.merge(options))
end

def create_change(options={})
  event = options.delete(:event) || create_event
  CIA::AttributeChange.create!({event: event, source: event.source, attribute_name: "bar"}.merge(options))
end

# simulate a hacked cia event
CIA::Event.class_eval do
  before_save :hacked_before_save
  attr_accessor :hacked_before_save_action

  def hacked_before_save
    hacked_before_save_action.call(self) if hacked_before_save_action
  end
end
