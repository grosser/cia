require 'spec_helper'

describe ActiveAuditing do
  it "has a VERSION" do
    ActiveAuditing::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe ".audit" do
    it "has no transaction when it starts" do
      ActiveAuditing.current_transaction.should == ActiveAuditing::NullTransaction
    end

    it "starts a new transaction" do
      result = 1
      ActiveAuditing.audit({}) do
        result = ActiveAuditing.current_transaction
      end
      result.class.should == ActiveAuditing::Transaction
    end

    it "stops the transaction after the block" do
      ActiveAuditing.audit({}){}
      ActiveAuditing.current_transaction.should == ActiveAuditing::NullTransaction
    end

    it "returns the block content" do
      ActiveAuditing.audit({}){ 1 }.should == 1
    end

    it "is threadsafe" do
      Thread.new do
        ActiveAuditing.audit({}) do
          sleep 0.04
        end
      end
      sleep 0.01
      ActiveAuditing.current_transaction.should == ActiveAuditing::NullTransaction
      sleep 0.04 # so next tests dont fail
    end
  end

  describe ".record_audit" do
    let(:object) { Car.new }
    let(:transaction) { ActiveAuditing.current_transaction }

    around do |example|
      ActiveAuditing.audit :actor => User.create! do
        example.call
      end
    end

    before do
      Rails.stub(:logger).and_return(mock(:error => ""))
      Rails.env.stub(:production?).and_return(true)
    end

    it "tracks create" do
      expect{
        object.save!
      }.to change{ ActiveAuditing::Event.count }.by(+1)
      ActiveAuditing::Event.last.class.should == ActiveAuditing::CreateEvent
    end

    it "tracks delete" do
      object.save!
      expect{
        object.destroy
      }.to change{ ActiveAuditing::Event.count }.by(+1)
      ActiveAuditing::Event.last.class.should == ActiveAuditing::DeleteEvent
    end

    it "tracks update" do
      object.save!
      expect{
        object.update_attributes(:wheels => 3)
      }.to change{ ActiveAuditing::Event.count }.by(+1)
      ActiveAuditing::Event.last.class.should == ActiveAuditing::UpdateEvent
    end

    context "exceptions" do
      before do
        Rails.stub(:logger).and_return(mock(:error => ""))
        Rails.env.stub(:production?).and_return(true)
        transaction.stub(:record).and_raise(StandardError.new("foo"))
      end

      it "logs exceptions raised by the transaction" do
        Rails.logger.should_receive(:error).with { |x| x =~ /Failed to record audit: foo/ }
        object.save! rescue nil
      end

      it "re-raise exceptions when not in production" do
        Rails.env.stub(:production?).and_return(false)

        expect {
          object.save!
        }.to raise_error(StandardError)
      end

      it "does not re-raise exceptions when in production" do
        Rails.env.stub(:production?).and_return(true)
        object.save!
      end
    end
  end
end
