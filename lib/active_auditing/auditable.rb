module ActiveAuditing
  module Auditable
    def self.included(base)
      base.class_attribute :audited_attributes
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def audit_attribute(*attributes)
        #options = attributes.extract_options!
        self.audited_attributes = Set.new unless audited_attributes
        self.audited_attributes += attributes.map(&:to_s)

        # new auditing system
        has_many :audit_events, :class_name => "ActiveAuditing::Event", :as => :source
        has_many :audit_attribute_changes, :class_name => "ActiveAuditing::AttributeChange", :as => :source
        ActiveAuditing::AuditObserver.instance.observe_me!(self)
      end
    end
  end
end
