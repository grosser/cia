module CIA
  class Event < ActiveRecord::Base
    self.table_name = "cia_events"

    belongs_to :actor, :polymorphic => true
    belongs_to :source, :polymorphic => true
    has_many :attribute_changes, :foreign_key => :cia_event_id

    validates_presence_of :action
    validates_presence_of :source, :if => :source_must_be_exist?

    def self.previous
      scoped(:order => "created_at desc")
    end

    def attribute_change_hash
      attribute_changes.inject({}) do |h, a|
        h[a.attribute_name] = [a.old_value, a.new_value]; h
      end
    end

    # tested via transaction_test.rb
    def add_attribute_changes(changes)
      changes.each do |attribute_name, (old_value, new_value)|
        attribute_changes.build(
          :event => self,
          :attribute_name => attribute_name,
          :old_value => old_value,
          :new_value => new_value,
          :source => source
        )
      end
    end

    def real_source_type
      attributes['source_type']
    end

    def virtual_source_type
      "CIA::VirtualSourceType::#{real_source_type}"
    end

    def source_type
      return real_source_type if real_source_type.nil? || !attributes.key?("source_display_name") || source_display_name.blank?

      size = virtual_source_type.split('::').size
      virtual_source_type.split('::').each_with_index.inject(Object) do |o, (c, i)|
        if o.constants.include?(c.to_sym)
          o.const_get(c)
        else
          i < size - 1 ? o.const_set(c, Module.new) : o.const_set(c, Class.new(CIA::FakeActiveRecord))
        end
      end
      virtual_source_type
    end

    private

    def source_must_be_exist?
      new_record? and action != "destroy" and (!attributes.key?("source_display_name") or source_display_name.blank?)
    end
  end
end
