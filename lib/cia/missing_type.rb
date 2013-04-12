module CIA
  # use this to enable .include / .source for source_types that do not exist
  # Fake::Model = Class.new(CIA::MissingType)
  class MissingType < ActiveRecord::Base
    default_scope :conditions => "1 = 2", :limit => 0

    self.table_name = "schema_migrations"

    def self.primary_key
      "version"
    end

    def readonly?
      true
    end
  end
end
