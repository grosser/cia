require 'spec_helper'

describe CIA do
  it "has a VERSION" do
    CIA::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe ".audit" do
    it "has no transaction when it starts" do
      CIA.current_transaction.should == CIA::NullTransaction
    end

    it "starts a new transaction" do
      result = 1
      CIA.audit({}) do
        result = CIA.current_transaction
      end
      result.class.should == CIA::Transaction
    end

    it "stops the transaction after the block" do
      CIA.audit({}){}
      CIA.current_transaction.should == CIA::NullTransaction
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
      CIA.current_transaction.should == CIA::NullTransaction
      sleep 0.04 # so next tests dont fail
    end
  end

  describe ".record_audit" do
    let(:object) { Car.new }
    let(:transaction) { CIA.current_transaction }

    around do |example|
      CIA.audit :actor => User.create! do
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
      }.to change{ CIA::Event.count }.by(+1)
      CIA::Event.last.class.should == CIA::CreateEvent
    end

    it "tracks delete" do
      object.save!
      expect{
        object.destroy
      }.to change{ CIA::Event.count }.by(+1)
      CIA::Event.last.class.should == CIA::DeleteEvent
    end

    it "tracks update" do
      object.save!
      expect{
        object.update_attributes(:wheels => 3)
      }.to change{ CIA::Event.count }.by(+1)
      CIA::Event.last.class.should == CIA::UpdateEvent
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
