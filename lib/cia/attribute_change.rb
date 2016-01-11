require "json"

module CIA
  class AttributeChange < ActiveRecord::Base
    include SourceValidation
    self.table_name = "cia_attribute_changes"

    belongs_to :event, foreign_key: "cia_event_id", inverse_of: :attribute_changes
    belongs_to :source, polymorphic: true

    validates_presence_of :event, :attribute_name

    scope :previous, lambda { order("id desc") }

    delegate :created_at, to: :event

    def self.on_attribute(attribute)
      where(attribute_name: attribute)
    end

    def self.max_value_size
      @max_value_size ||= (columns.detect { |c| c.name == "old_value" }.limit || 255)
    end

    def self.serialize_for_storage(item, &block)
      raise "Pass me a block to reduce size" unless block_given?
      before, json = nil

      loop do
        json = JSON.dump(item)
        raise "The block did not reduce the size" if before && json.bytesize >= before
        before = json.bytesize
        break if max_value_size >= before
        item = yield(item)
      end

      json
    end

    private

    def source_must_be_present?
      event.present? && event.source_must_be_present?
    end
  end
end
