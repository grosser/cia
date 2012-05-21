module ActiveAuditing
  class AuditObserver < ActiveRecord::Observer
    def observe_me!(klass)
      descendants = if ActiveRecord::VERSION::MAJOR == 2
        klass.send(:subclasses)
      else
        klass.descendants
      end
      to_observe = [klass] + descendants

      (to_observe - observed_classes.to_a).each do |klass|
        observed_classes << klass
        add_observer! klass
      end
    end

    def after_create(object)
      record ActiveAuditing::CreateEvent, object
    end

    def after_destroy(object)
      record ActiveAuditing::DeleteEvent, object
    end

    def after_update(object)
      record ActiveAuditing::UpdateEvent, object
    end

    private

    attr_writer :observed_classes
    def observed_classes
      @observed_classes ||= Set.new
    end

    def record(event_type, object)
      ActiveAuditing.current_transaction.record(event_type, object)
    rescue => e
      Rails.logger.error("Failed to record audit: #{e}\n#{e.backtrace}")
      raise e unless Rails.env.production?
    end
  end
end
