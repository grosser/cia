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
end
