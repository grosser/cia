require 'active_record'
require 'cia/version'
require 'cia/auditable'

module CIA
  autoload 'Event', 'cia/event'
  autoload 'AttributeChange', 'cia/attribute_change'

  class << self
    attr_accessor :exception_handler
  end

  def self.audit(options = {})
    old = Thread.current[:cia_transaction]
    Thread.current[:cia_transaction] = options
    yield
  ensure
    Thread.current[:cia_transaction] = old
  end

  def self.current_transaction
    Thread.current[:cia_transaction]
  end

  def self.record(action, source)
    return unless current_transaction
    options = source.class.audited_attribute_options
    return if options and options[:if] and not source.send(options[:if])

    changes = source.changes.slice(*source.class.audited_attributes)
    message = source.audit_message if source.respond_to?(:audit_message)

    return if not message and changes.empty? and action.to_s == "update"

    event = CIA::Event.create!(current_transaction.merge(
      :action => action.to_s,
      :source => source,
      :message => message
    ))
    event.record_attribute_changes!(changes)
    event
  rescue Object => e
    if exception_handler
      exception_handler.call e
    else
      raise e
    end
  end
end
