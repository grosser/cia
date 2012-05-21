module CIA
  class Event < ActiveRecord::Base
    abstract_class
    self.table_name = "audit_events"

    belongs_to :source, :polymorphic => true
    belongs_to :transaction, :foreign_key => :audit_transaction_id
    has_many :attribute_changes, :foreign_key => :audit_event_id

    validates_presence_of :transaction, :source, :type

    # tested via transaction_test.rb
    def record_attribute_changes!(changes)
      changes.each do |attribute_name, (old_value, new_value)|
        attribute_changes.create!(
          :attribute_name => attribute_name,
          :old_value => old_value,
          :new_value => new_value,
          :source => source
        )
      end
    end
  end
end
