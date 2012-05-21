module CIA
  class Transaction < ActiveRecord::Base
    self.table_name = "audit_transactions"

    belongs_to :actor, :polymorphic => true
    has_many :events, :foreign_key => :audit_transaction_id

    def record(event_type, source)
      changes = source.changes.slice(*source.class.audited_attributes)
      message = source.audit_message if source.respond_to?(:audit_message)

      return if not message and changes.empty? and event_type == CIA::UpdateEvent

      event = event_type.create!(
        :source => source,
        :transaction => self,
        :message => message
      )
      event.record_attribute_changes!(changes)
      event
    end
  end
end
