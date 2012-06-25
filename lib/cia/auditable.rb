module CIA
  module Auditable
    def self.included(base)
      base.class_attribute :audited_attributes
      base.send :extend, ClassMethods
      base.after_create {|record| CIA.record(:create, record) }
      base.after_update {|record| CIA.record(:update, record) }
      base.after_destroy {|record| CIA.record(:destroy, record) }
    end

    module ClassMethods
      def audit_attribute(*attributes)
        self.audited_attributes = Set.new unless audited_attributes
        self.audited_attributes += attributes.map(&:to_s)

        has_many :cia_events, :class_name => "CIA::Event", :as => :source
        has_many :cia_attribute_changes, :class_name => "CIA::AttributeChange", :as => :source
      end
    end
  end
end
