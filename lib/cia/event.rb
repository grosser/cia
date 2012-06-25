module CIA
  class Event < ActiveRecord::Base
    self.table_name = "cia_events"

    belongs_to :actor, :polymorphic => true
    belongs_to :source, :polymorphic => true
    has_many :attribute_changes, :foreign_key => :cia_event_id

    validates_presence_of :source, :action

    def self.previous
      scoped(:order => "id desc")
    end

    def attribute_change_hash
      attribute_changes.inject({}) do |h, a|
        h[a.attribute_name] = [a.old_value, a.new_value]; h
      end
    end

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
