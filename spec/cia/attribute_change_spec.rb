require 'spec_helper'

describe CIA::AttributeChange do
  it "delegates create_at to event" do
    t = Time.now
    event = CIA::Event.new(:created_at => t)
    change = CIA::AttributeChange.new(:event => event)
    change.created_at.should == event.created_at
  end

  describe ".previous" do
    it "finds by id desc" do
      a = create_change
      b = create_change
      CIA::AttributeChange.previous.should == [b,a]
    end
  end
end
