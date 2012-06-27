require 'spec_helper'

describe CIA::Event do
  it "has many attribute_changes" do
    change = create_change
    change.event.attribute_changes.should == [change]
  end

  context "attribute_change_hash" do
    it "is empty for empty changes" do
      create_event.attribute_change_hash.should == {}
    end

    it "contains all changes" do
      change = create_change(:old_value => "a", :new_value => "b")
      change = create_change(:attribute_name => "foo", :old_value => "b", :new_value => nil, :event => change.event)
      change.event.attribute_change_hash.should == {"bar" => ["a", "b"], "foo" => ["b", nil]}
    end
  end

  context ".previous" do
    it "is sorted id desc" do
      events = [create_event(:created_at => 3.days.ago), create_event(:created_at => 2.days.ago), create_event(:created_at => 1.day.ago)].map(&:id)
      CIA::Event.previous.map(&:id).should == events.reverse
    end
  end
end
