require 'active_record'
require 'cia/version'
require 'cia/auditable'

module CIA
  autoload 'Event', 'cia/event'
  autoload 'AttributeChange', 'cia/attribute_change'
  autoload 'SourceValidation', 'cia/source_validation'

  class << self
    attr_accessor :exception_handler
    attr_accessor :non_recordable_attributes
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

  def self.current_actor=(user)
    current_transaction[:actor] = user if current_transaction
  end

  def self.current_actor
    current_transaction[:actor] if current_transaction
  end

  def self.record(action, source)
    return unless current_transaction
    options = source.class.audited_attribute_options
    return if options and options[:if] and not source.send(options[:if])
    return if options and options[:unless] and source.send(options[:unless])

    changes = (source.cia_previous_changes || source.cia_changes).slice(*source.class.audited_attributes)
    message = source.audit_message.presence if source.respond_to?(:audit_message)

    return if not message and changes.empty? and action.to_s == "update"

    transaction_attributes = current_transaction.dup
    transaction_attributes.reject! { |k, v| non_recordable_attributes.include?(k) } if non_recordable_attributes

    event = CIA::Event.new(transaction_attributes.merge(
      :action => action.to_s,
      :source => source,
      :message => message
    ))
    event.add_attribute_changes(changes)
    event.save!
    event
  rescue Object => e
    if exception_handler
      exception_handler.call e
    else
      raise e
    end
  end
end
