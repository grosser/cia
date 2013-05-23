require 'spec_helper'

describe CIA::AttributeChange do
  it "stores times as db format" do
    t = Time.now
    create_change(:old_value => t).reload.old_value.sub(/\.\d+$/,'').should == t.to_s(:db)
  end

  it "stores dates as db format" do
    create_change(:old_value => Date.new(2012)).reload.old_value.should == "2012-01-01"
  end

  it "stores booleans as db format" do
    create_change(:old_value => false).reload.old_value.should == "f"
    create_change(:old_value => true).reload.old_value.should == "t"
  end

  it "stores nil as nil" do
    create_change(:old_value => nil).reload.old_value.should == nil
  end

  it "delegates create_at to event" do
    t = Time.now
    event = CIA::Event.new(:created_at => t)
    change = CIA::AttributeChange.new(:event => event)
    change.created_at.should == event.created_at
  end

  describe ".previous" do
    it "finds by id desc" do
      CIA::AttributeChange.delete_all
      a = create_change
      b = create_change
      CIA::AttributeChange.previous.should == [b,a]
    end
  end

  describe ".on_attribute" do
    it "finds with attribute" do
      a = create_change :attribute_name => :xxx
      b = create_change :attribute_name => :yyy
      CIA::AttributeChange.on_attribute(:xxx).all.should == [a]
    end
  end

  describe "enforcing presence of source" do
    it "requires a source when associated event requires a source" do
      event = CIA::Event.new(:id => 1)
      event.stub(:source_must_be_present? => true)
      change = CIA::AttributeChange.new(:event => event, :attribute_name => 'awesomeness')

      change.valid?.should be_false
      change.errors.full_messages.should =~ ["Source can't be blank"]
    end

    it "does not require a source when associated event does not" do
      event = CIA::Event.new(:id => 1)
      event.stub(:source_must_be_present? => false)
      change = CIA::AttributeChange.new(:event => event, :attribute_name => 'awesomeness',
                                        :source_type => 'ObscureType', :source_id => 101)

      change.valid?.should be_true
    end
  end
end
