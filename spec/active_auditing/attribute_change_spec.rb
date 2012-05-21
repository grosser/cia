require 'spec_helper'

describe ActiveAuditing::AttributeChange do
  it "delegates create_at to event" do
    t = Time.now
    event = ActiveAuditing::Event.new(:created_at => t)
    change = ActiveAuditing::AttributeChange.new(:event => event)
    change.created_at.should == event.created_at
  end

  describe ".previous" do
    it "finds by id desc" do
      a = create_change
      b = create_change
      ActiveAuditing::AttributeChange.previous.should == [b,a]
    end
  end
end
