require 'spec_helper'

module CIA
  describe FakeActiveRecord do
    it "should return empty array for finder" do
      FakeActiveRecord.find(1).should be_empty
    end

    it "should return quoted table name" do
      FakeActiveRecord.quoted_table_name.should == "a_fake_active_record_table_name"
    end

    it "should return primary key" do
      FakeActiveRecord.primary_key.should == FakeActiveRecord::PRIMARY_KEY
    end

    it "should return first column" do
      FakeActiveRecord.columns.first.type.should == :integer
    end

    it "should respond to with_exclusive_scope" do
      FakeActiveRecord.should respond_to(:with_exclusive_scope)
    end
  end
end
