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

    it "does not track failed changes" do
      car = Car.create!(:wheels => 1).id
      expect{
        expect{ FailCar.new(:wheels => 4).save  }.to raise_error(FailCar::Oops)
        car = FailCar.find(car)
        expect{ car.update_attributes(:wheels => 2) }.to raise_error(FailCar::Oops)
        expect{ car.destroy }.to raise_error(FailCar::Oops)
      }.to_not change{ CIA::Event.count }
    end

    it "is rolled back if auditing fails" do
      CIA.should_receive(:record).and_raise("XXX")
      expect{
        expect{
          CIA.audit{ object.save! }
        }.to raise_error("XXX")
      }.to_not change{ object.class.count }
    end

    it "is ok with non-attribute methods passed into .audit if they are set as non-recordable" do
      CIA.non_recordable_attributes = [:foo]
      expect {
        CIA.audit(:actor => User.create!, :foo => 'bar') {
          object.save!
        }
      }.to change{ CIA::Event.count }.by(+1)
    end

    context "nested classes with multiple audited_attributes" do
      let(:object){ NestedCar.new }

      it "has the exclusive sub-classes attributes of the nested class" do
        object.class.audited_attributes.should == ["drivers"]
      end

      it "does not record twice for nested classes" do
        expect{
          CIA.audit{ object.save! }
        }.to change{ CIA::Event.count }.by(+1)
      end

      it "does not record twice for super classes" do
        expect{
          CIA.audit{ Car.new.save! }
        }.to change{ CIA::Event.count }.by(+1)
      end
    end

    context "nested classes with 1 audited_attributes" do
      let(:object){ InheritedCar.new }

      it "has the super-classes attributes" do
        object.class.audited_attributes.should == ["wheels"]
      end

      it "does not record twice for nested classes" do
        expect{
          CIA.audit{ object.save! }
        }.to change{ CIA::Event.count }.by(+1)
      end

      it "does not record twice for super classes" do
        expect{
          CIA.audit{ Car.new.save! }
        }.to change{ CIA::Event.count }.by(+1)
      end
    end

    context "custom changes" do
      let(:object) { CarWithCustomChanges.new }

      it "tracks custom changes" do
        object.save!
        expect{
          object.update_attributes(:wheels => 3)
        }.to change{ CIA::Event.count }.by(+1)
        CIA::Event.last.action.should == "update"
        CIA::Event.last.attribute_change_hash.should == {
          "wheels" => [nil, "3"],
          "foo" => ["bar", "baz"]
        }
      end
    end

    context ":if" do
      let(:object) { CarWithIf.new }

      it "tracks if :if is true" do
        expect{
          object.tested = true
          object.save!
        }.to change{ CIA::Event.count }.by(+1)
        CIA::Event.last.action.should == "create"
      end

      it "does not track if :if is false" do
        expect{
          object.save!
        }.to_not change{ CIA::Event.count }
        CIA::Event.last.should == nil
      end
    end

    context ":unless" do
      let(:object) { CarWithUnless.new }

      it "tracks if :unless is false" do
        expect{
          object.save!
        }.to change{ CIA::Event.count }.by(+1)
        CIA::Event.last.action.should == "create"
      end

      it "does not track if :unless is true" do
        expect{
          object.tested = true
          object.save!
        }.to_not change{ CIA::Event.count }
        CIA::Event.last.should == nil
      end
    end

    context "events" do
      def parse_event_changes(event)
        event.attribute_changes.map { |c| [c.attribute_name, c.old_value, c.new_value] }
      end

      def no_audit_created!
        event = nil
        expect{
          event = yield
        }.to_not change{ CIA::Event.count }

        event.should == nil
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
        event = CIA.record(:update, source).reload

        parse_event_changes(event).should == [["wheels", nil, "4"]]
      end

      it "can act on attributes in before_save" do
        x = nil
        CIA.current_transaction[:hacked_before_save_action] = lambda{|event| x = event.attribute_changes.size }
        source = Car.create!
        source.wheels = 4
        CIA.record(:update, source)
        x.should == 1
      end

      it "records multiple attributes" do
        source = CarWith3Attributes.create!
        source.wheels = 4
        source.drivers = 2
        source.color = "red"
        event = CIA.record(:update, source).reload
        parse_event_changes(event).should =~ [["wheels", nil, "4"], ["drivers", nil, "2"], ["color", nil, "red"]]
      end

      it "records attribute changes" do
        source = Car.create!(:wheels => 2)
        source.wheels = 4
        event = CIA.record(:update, source).reload
        parse_event_changes(event).should == [["wheels", "2", "4"]]
      end

      it "records attribute deletions" do
        source = Car.create!(:wheels => 2)
        source.wheels = nil
        event = CIA.record(:update, source).reload
        parse_event_changes(event).should == [["wheels", "2", nil]]
      end

      it "does not record unaudited attribute changes" do
        source = Car.create!
        source.drivers = 2
        no_audit_created!{ CIA.record(:update, source) }
      end

      it "records audit_message as message even if there are no changes" do
        source = CarWithAMessage.create!
        source.audit_message = "Foo"
        event = CIA.record(:update, source)

        event.message.should == "Foo"
        parse_event_changes(event).should == []
      end

      it "does not record if it's empty and there are no changes" do
        source = CarWithAMessage.create!
        source.audit_message = "   "
        no_audit_created!{ CIA.record(:update, source) }
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
        ensure
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

    context "with after_commit" do
      let(:object){ CarWithTransactions.new(:wheels => 1) }

      it "still tracks" do
        expect{
          CIA.audit{ object.save! }
        }.to change{ CIA::Event.count }.by(+1)
        CIA::Event.last.attribute_change_hash.should == {"wheels" => [nil, "1"]}
      end

      it "unsets temp-changes after the save" do
        object.save!

        # does not re-track old changes
        expect{
          CIA.audit{ object.update_attributes(:drivers => 2) }
        }.to change{ CIA::Event.count }.by(+1)
        CIA::Event.last.attribute_change_hash.should == {"drivers" => [nil, "2"]}

        # empty changes
        expect{
          CIA.audit{ object.update_attributes(:drivers => 2) }
        }.to_not change{ CIA::Event.count }
      end

      it "is not rolled back if auditing fails" do
        CIA.should_receive(:record).and_raise("XXX")
        begin
          expect{
            CIA.audit{ object.save! }
          }.to change{ object.class.count }.by(+1)
        rescue RuntimeError => e
          # errors from after_commit are never raised in rails 3+
          raise e if ActiveRecord::VERSION::MAJOR != 2 || e.message != "XXX"
        end
      end
    end
  end

  context ".current_actor" do
    it "is nil when nothing is set" do
      CIA.current_actor.should == nil
    end

    it "is nil when no actor is set" do
      CIA.audit do
        CIA.current_actor.should == nil
      end
    end

    it "is the current :actor" do
      CIA.audit :actor => 111 do
        CIA.current_actor.should == 111
      end
    end
  end

  context ".current_actor=" do
    it "does nothing if no transaction is running" do
      CIA.current_actor = 111
      CIA.current_transaction.should == nil
    end

    it "sets when transaction is started" do
      CIA.audit :actor => 222 do
        CIA.current_actor = 111
        CIA.current_transaction.should == {:actor => 111}
      end
    end
  end
end
