require_relative "./source_validation"

module CIA
  module EventMethods
    extend ActiveSupport::Concern
    include SourceValidation

    included do
      self.table_name = "cia_events"
      belongs_to :actor, polymorphic: true
      belongs_to :source, polymorphic: true
      has_many :attribute_changes, foreign_key: :cia_event_id, inverse_of: :event, dependent: :destroy

      validates_presence_of :action
    end

    class_methods do
      def previous
        order("created_at desc")
      end
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
          event: self,
          attribute_name: attribute_name,
          old_value: old_value,
          new_value: new_value,
          source: source
        )
      end
    end

    def source_must_be_present?
      new_record? and action != "destroy" and (!attributes.key?("source_display_name") or source_display_name.blank?)
    end
  end
end
