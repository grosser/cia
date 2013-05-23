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

  context "validations" do
    let(:source_attributes){ {:source => nil, :source_id => 99999, :source_type => "Car"} }

    it "validates source" do
      expect{
        create_event(source_attributes)
      }.to raise_error
    end

    it "does not validates source when action is destroy" do
      create_event(source_attributes.merge(:action => "destroy"))
    end

    it "does not validates source when updating" do
      create_event.update_attributes!(:source_id => 9999)
    end

    it "does not validates source when source_display_name is present" do
      create_event(:source => nil, :source_id => -111, :source_type => 'FakeTypeHere', :source_display_name => 'abc')
    end

    it "validates source when source_display_name is blank" do
      expect{
        create_event(:source => nil, :source_id => -111, :source_type => 'FakeTypeHere', :source_display_name => '')
      }.to raise_error
    end
  end

  context "source_type" do
    context "with no source_display_name" do
      let(:car) { Car.create! }
      let(:source_attributes) { {:source => car, :source_id => car.id, :source_type => "Car"} }
      it "should return source type in db" do
        event = create_event(source_attributes)
        event.source_type.should == 'Car'
      end
    end

    context "with source_display_name" do
      let(:car) { Car.create! }
      let(:source_attributes) { {:source => nil, :source_id => car.id, :source_type => "Car", :source_display_name => 'abc'} }
      it "should return virtual source type in db" do
        event = create_event(source_attributes)
        event.source_type.should == 'CIA::VirtualSourceType::Car'
      end
    end
  end

  context "real_source_type" do
    context "with no source_display_name" do
      let(:car) { Car.create! }
      let(:source_attributes) { {:source => car, :source_id => car.id, :source_type => "Car"} }
      it "should return source type in db" do
        event = create_event(source_attributes)
        event.real_source_type.should == 'Car'
      end
    end

    context "with source_display_name" do
      let(:car) { Car.create! }
      let(:source_attributes) { {:source => nil, :source_id => car.id, :source_type => "Car", :source_display_name => 'abc'} }
      it "should return virtual source type in db" do
        event = create_event(source_attributes)
        event.real_source_type.should == 'Car'
      end
    end
  end

  context "virtual_source_type" do
    context "with no source_display_name" do
      let(:car) { Car.create! }
      let(:source_attributes) { {:source => car, :source_id => car.id, :source_type => "Car"} }
      it "should return virtual source type in db" do
        event = create_event(source_attributes)
        event.virtual_source_type.should == 'CIA::VirtualSourceType::Car'
      end
    end

    context "with source_display_name" do
      let(:car) { Car.create! }
      let(:source_attributes) { {:source => nil, :source_id => car.id, :source_type => "Car", :source_display_name => 'abc'} }
      it "should return virtual source type in db" do
        event = create_event(source_attributes)
        event.virtual_source_type.should == 'CIA::VirtualSourceType::Car'
      end
    end
  end
end
