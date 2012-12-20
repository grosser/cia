module CIA
  module Auditable
    def self.included(base)
      base.class_attribute :audited_attributes, :audited_attribute_options
      base.send :extend, ClassMethods
      base.after_create {|record| CIA.record(:create, record) }
      base.after_update {|record| CIA.record(:update, record) }
      base.after_destroy {|record| CIA.record(:destroy, record) }
    end

    def cia_changes
      changes
    end

    module ClassMethods
      def audit_attribute(*attributes)
        options = (attributes.last.is_a?(Hash) ? attributes.pop : {})

        self.audited_attributes = Set.new unless audited_attributes
        self.audited_attributes += attributes.map(&:to_s)

        raise "cannot have :if and :unless" if options[:if] && options[:unless]
        self.audited_attribute_options ||= {}
        self.audited_attribute_options.merge!(options)

        has_many :cia_events, :class_name => "CIA::Event", :as => :source
        has_many :cia_attribute_changes, :class_name => "CIA::AttributeChange", :as => :source
      end
    end
  end
end
