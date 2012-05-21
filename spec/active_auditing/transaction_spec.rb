require 'spec_helper'

describe ActiveAuditing::Transaction do
  it "has many events" do
    event = create_event
    event.transaction.events.should == [event]
  end

  context "#record" do
    def parse_event_changes(event)
      event.attribute_changes.map { |c| [c.attribute_name, c.old_value, c.new_value] }
    end

    let(:transaction){ ActiveAuditing::Transaction.new(:actor => User.create!) }

    it "records attribute creations" do
      source = Car.create!
      source.wheels = 4
      event = transaction.record(ActiveAuditing::UpdateEvent, source)

      parse_event_changes(event).should == [["wheels", nil, "4"]]
    end

    it "records multiple attributes" do
      source = CarWith3Attributes.create!
      source.wheels = 4
      source.drivers = 2
      source.color = "red"
      event = transaction.record(ActiveAuditing::UpdateEvent, source)

      parse_event_changes(event).should =~ [["wheels", nil, "4"], ["drivers", nil, "2"], ["color", nil, "red"]]
    end

    it "records attribute changes" do
      source = Car.create!(:wheels => 2)
      source.wheels = 4
      event = transaction.record(ActiveAuditing::UpdateEvent, source)
      parse_event_changes(event).should == [["wheels", "2", "4"]]
    end

    it "records attribute deletions" do
      source = Car.create!(:wheels => 2)
      source.wheels = nil
      event = transaction.record(ActiveAuditing::UpdateEvent, source)
      parse_event_changes(event).should == [["wheels", "2", nil]]
    end

    it "does not record unaudited attribute changes" do
      source = Car.create!
      source.drivers = 2
      event = nil
      expect{
        event = transaction.record(ActiveAuditing::UpdateEvent, source)
      }.to_not change{ ActiveAuditing::Event.count }

      event.should == nil
    end

    it "records audit_message as message even if there are no changes" do
      source = CarWithAMessage.create!
      source.audit_message = "Foo"
      event = transaction.record(ActiveAuditing::UpdateEvent, source)

      event.message.should == "Foo"
      parse_event_changes(event).should == []
    end

    it "record non-updates even without changes" do
      source = Car.create!
      event = transaction.record(ActiveAuditing::CreateEvent, source)

      parse_event_changes(event).should == []
    end
  end
end
