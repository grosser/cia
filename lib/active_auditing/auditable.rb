module ActiveAuditing
  module Auditable
    def self.included(base)
      base.class_attribute :audited_attributes
      base.send :extend, ClassMethods
      base.after_create {|record| ActiveAuditing.record_audit(ActiveAuditing::CreateEvent, record) }
      base.after_update {|record| ActiveAuditing.record_audit(ActiveAuditing::UpdateEvent, record) }
      base.after_destroy {|record| ActiveAuditing.record_audit(ActiveAuditing::DeleteEvent, record) }
    end

    module ClassMethods
      def audit_attribute(*attributes)
        self.audited_attributes = Set.new unless audited_attributes
        self.audited_attributes += attributes.map(&:to_s)

        has_many :audit_events, :class_name => "ActiveAuditing::Event", :as => :source
        has_many :audit_attribute_changes, :class_name => "ActiveAuditing::AttributeChange", :as => :source
      end
    end
  end
end
