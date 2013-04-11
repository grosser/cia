module CIA
  class FakeActiveRecord
    # we use this to enable includes on associations that contain types that do not exist
    PRIMARY_KEY = 'a_fake_active_record_table_primary_key'

    class FakeColumn
      def type
        :integer
      end

      def name
        PRIMARY_KEY
      end
    end

    def self.find(*args)
      []
    end

    def self.quoted_table_name
      'a_fake_active_record_table_name'
    end

    def self.primary_key
      PRIMARY_KEY
    end

    def self.columns
      [FakeColumn.new]
    end

    def self.with_exclusive_scope(*args, &block)
      yield
    end
  end
end
