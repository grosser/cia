require 'spec_helper'

describe ActiveAuditing::AuditObserver do
  def observe!(object, event)
    raise "#{object.class} is not observed" unless observer.send(:observed_classes).include?(object.class)
    observer.update(event, object)
  end

  context ActiveAuditing::AuditObserver do
    let(:object){ Car.new }
    let(:observer){ ActiveAuditing::AuditObserver.instance }
    let(:transaction){ ActiveAuditing.current_transaction }

    around do |example|
      ActiveAuditing.audit do
        example.call
      end
    end

    describe "#after_create" do
      it "calls transaction#record" do
        transaction.should_receive(:record).with(ActiveAuditing::CreateEvent, object)
        observe! object, :after_create
      end
    end

    describe "#after_destroy" do
      it "calls transaction#record" do
        transaction.should_receive(:record).with(ActiveAuditing::DeleteEvent, object)
        observe! object, :after_destroy
      end
    end

    describe "#after_update" do
      it "calls transaction#record" do
        transaction.should_receive(:record).with(ActiveAuditing::UpdateEvent, object)
        observe! object, :after_update
      end
    end

    it "does not call the transaction on any other event" do
      transaction.should_not_receive(:record)
      observe! object, :after_kitten_attack
    end

    context "exceptions" do
      before do
        Rails.stub(:logger).and_return(mock(:error => ""))
        Rails.env.stub(:production?).and_return(true)
        transaction.stub(:record).and_raise(StandardError.new("foo"))
      end

      it "logs exceptions raised by the transaction" do
        Rails.logger.should_receive(:error).with{|x| x =~ /Failed to record audit: foo/ }
        observe! object, :after_create rescue nil
      end

      it "re-raise exceptions when not in production" do
        Rails.env.stub(:production?).and_return(false)

        expect{
          observe! object, :after_create
        }.to raise_error(StandardError)
      end

      it "does not re-raise exceptions when in production" do
        Rails.env.stub(:production?).and_return(true)
        observe! object, :after_create
      end
    end

    describe "#observe_me!" do
      let(:descendants){ ActiveRecord::VERSION == 2 ? :subclasses : :descendants }

      before do
        @a = CarWithoutObservers
        @b = CarWithoutObservers2
        @old = observer.send(:observed_classes).dup
      end

      after do
        observer.send :observed_classes=, @old
      end

      it "add the class" do
        @a.stub(descendants).and_return []
        @a.should_receive(:add_observer).with(observer)
        observer.observe_me! @a
      end

      it "add the subclasses of the class" do
        @a.should_receive(descendants).and_return([@b])
        @a.should_receive(:add_observer).with(observer)
        @b.should_receive(:add_observer).with(observer)
        observer.observe_me! @a
      end

      it "not add duplicates" do
        @b.should_receive(descendants).and_return([])
        @b.should_receive(:add_observer).with(observer)
        observer.observe_me! @b

        @a.should_receive(descendants).and_return([@b])
        @a.should_receive(:add_observer).with(observer)
        @b.should_receive(:add_observer).never # already added
        observer.observe_me! @a
      end
    end
  end
end
