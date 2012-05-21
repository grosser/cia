require 'spec_helper'

describe ActiveAuditing::Event do
  it "has many attribute_changes" do
    change = create_change
    change.event.attribute_changes.should == [change]
  end
end
