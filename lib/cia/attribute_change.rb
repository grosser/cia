module CIA
  class AttributeChange < ActiveRecord::Base
    self.table_name = "cia_attribute_changes"

    belongs_to :event, :foreign_key => "cia_event_id"
    belongs_to :source, :polymorphic => true

    validates_presence_of :event, :attribute_name
    validates_presence_of :source, :if => :source_must_be_present?

    if ActiveRecord::VERSION::MAJOR > 2
      scope :previous, :order => "id desc"
    else
      named_scope :previous, :order => "id desc"
    end

    delegate :created_at, :to => :event

    def self.on_attribute(attribute)
      scoped(:conditions => {:attribute_name => attribute})
    end

    private

    def source_must_be_present?
      event.present? && event.source_must_be_present?
    end
  end
end
