require 'active_record'
require 'active_auditing/version'
require 'active_auditing/auditable'
require 'active_auditing/null_transaction'

require 'active_auditing/transaction'
require 'active_auditing/event'
require 'active_auditing/create_event'
require 'active_auditing/update_event'
require 'active_auditing/delete_event'
require 'active_auditing/attribute_change'

module ActiveAuditing
  def self.audit(options = {})
    Thread.current[:audit_transaction] = Transaction.new(options)
    yield
  ensure
    Thread.current[:audit_transaction] = nil
  end

  def self.current_transaction
    Thread.current[:audit_transaction] || NullTransaction
  end

  def self.record_audit(event_type, object)
    ActiveAuditing.current_transaction.record(event_type, object)
  rescue => e
    Rails.logger.error("Failed to record audit: #{e}\n#{e.backtrace}")
    raise e unless Rails.env.production?
  end
end
