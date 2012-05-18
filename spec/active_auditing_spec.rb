require 'spec_helper'

describe ActiveAuditing do
  it "has a VERSION" do
    ActiveAuditing::VERSION.should =~ /^[\.\da-z]+$/
  end
end
