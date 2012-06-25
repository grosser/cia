require 'spec_helper'

describe CIA do
  it "has a VERSION" do
    CIA::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe ".audit" do
    it "has no transaction when it starts" do
      CIA.current_transaction.should == nil
    end

    it "starts a new transaction" do
      result = 1
      CIA.audit({:a => 1}) do
        result = CIA.current_transaction
      end
      result.should == {:a => 1}
    end

    it "stops the transaction after the block" do
      CIA.audit({}){}
      CIA.current_transaction.should == nil
    end

    it "returns the block content" do
      CIA.audit({}){ 1 }.should == 1
    end

    it "is threadsafe" do
      Thread.new do
        CIA.audit({}) do
          sleep 0.04
        end
      end
      sleep 0.01
      CIA.current_transaction.should == nil
      sleep 0.04 # so next tests dont fail
    end

    it "can stack" do
      states = []
      CIA.audit(:a => 1) do
        states << CIA.current_transaction
        CIA.audit(:b => 1) do
          states << CIA.current_transaction
        end
        states << CIA.current_transaction
      end
      states << CIA.current_transaction
      states.should == [{:a => 1}, {:b => 1}, {:a => 1}, nil]
    end
  end

  describe ".record" do
    let(:object) { Car.new }

    around do |example|
      CIA.audit :actor => User.create! do
        example.call
      end
    end

    it "tracks create" do
      expect{
        object.save!
      }.to change{ CIA::Event.count }.by(+1)
      CIA::Event.last.action.should == "create"
    end

    it "tracks delete" do
      object.save!
      expect{
        object.destroy
      }.to change{ CIA::Event.count }.by(+1)
      CIA::Event.last.action.should == "destroy"
    end

    it "tracks update" do
      object.save!
      expect{
        object.update_attributes(:wheels => 3)
      }.to change{ CIA::Event.count }.by(+1)
      CIA::Event.last.action.should == "update"
    end

    context "events" do
      def parse_event_changes(event)
        event.attribute_changes.map { |c| [c.attribute_name, c.old_value, c.new_value] }
      end

      it "records attributes in transaction" do
        event = nil
        CIA.audit :actor => User.create!, :ip_address => "1.2.3.4" do
          event = CIA.record(:destroy, Car.create!)
        end
        event.ip_address.should == "1.2.3.4"
      end

      it "records attribute creations" do
        source = Car.create!
        source.wheels = 4
        event = CIA.record(:update, source)

        parse_event_changes(event).should == [["wheels", nil, "4"]]
      end

      it "records multiple attributes" do
        source = CarWith3Attributes.create!
        source.wheels = 4
        source.drivers = 2
        source.color = "red"
        event = CIA.record(:update, source)

        parse_event_changes(event).should =~ [["wheels", nil, "4"], ["drivers", nil, "2"], ["color", nil, "red"]]
      end

      it "records attribute changes" do
        source = Car.create!(:wheels => 2)
        source.wheels = 4
        event = CIA.record(:update, source)
        parse_event_changes(event).should == [["wheels", "2", "4"]]
      end

      it "records attribute deletions" do
        source = Car.create!(:wheels => 2)
        source.wheels = nil
        event = CIA.record(:update, source)
        parse_event_changes(event).should == [["wheels", "2", nil]]
      end

      it "does not record unaudited attribute changes" do
        source = Car.create!
        source.drivers = 2
        event = nil
        expect{
          event = CIA.record(:update, source)
        }.to_not change{ CIA::Event.count }

        event.should == nil
      end

      it "records audit_message as message even if there are no changes" do
        source = CarWithAMessage.create!
        source.audit_message = "Foo"
        event = CIA.record(:update, source)

        event.message.should == "Foo"
        parse_event_changes(event).should == []
      end

      it "record non-updates even without changes" do
        source = Car.create!
        event = CIA.record(:create, source)

        parse_event_changes(event).should == []
      end
    end

    context "exception_handler" do
      before do
        $stderr.stub(:puts)
        CIA.stub(:current_transaction).and_raise(StandardError.new("foo"))
      end

      def capture_exception
        begin
          old = CIA.exception_handler
          ex = nil
          CIA.exception_handler = lambda{|e| ex = e }
          yield
          ex
        rescue
          CIA.exception_handler = old
        end
      end

      it "raises exceptions by the transaction" do
        ex = nil
        begin
          object.save!
        rescue Object => e
          ex = e
        end
        ex.inspect.should == '#<StandardError: foo>'
      end

      it "can capture exception via handler" do
        ex = capture_exception do
          object.save!
        end
        ex.inspect.should == '#<StandardError: foo>'
      end
    end
  end
end
