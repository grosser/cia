require 'active_record'
require 'cia/version'
require 'cia/auditable'
require 'cia/null_transaction'
require 'cia/transaction'
require 'cia/event'
require 'cia/create_event'
require 'cia/update_event'
require 'cia/delete_event'
require 'cia/attribute_change'

module CIA
  class << self
    attr_accessor :exception_handler
  end

  def self.audit(options = {})
    Thread.current[:cia_transaction] = Transaction.new(options)
    yield
  ensure
    Thread.current[:cia_transaction] = nil
  end

  def self.current_transaction
    Thread.current[:cia_transaction] || NullTransaction
  end

  def self.record_audit(event_type, object)
    CIA.current_transaction.record(event_type, object)
  rescue Object => e
    if exception_handler
      exception_handler.call e
    else
      raise e
    end
  end
end
