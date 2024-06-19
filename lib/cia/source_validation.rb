module CIA
  module SourceValidation
    extend ActiveSupport::Concern
    included do
      validates_presence_of :source_id, :source_type, unless: :source_must_be_present?
      validates_presence_of :source, if: :source_must_be_present?
    end
  end
end
