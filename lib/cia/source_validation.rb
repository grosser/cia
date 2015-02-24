module CIA
  module SourceValidation
    def self.included(base)
      base.validates_presence_of :source_id, :source_type, unless: :source_must_be_present?
      base.validates_presence_of :source, if: :source_must_be_present?
    end
  end
end
