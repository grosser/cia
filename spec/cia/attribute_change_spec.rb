# encoding: utf-8
require 'spec_helper'

describe CIA::AttributeChange do
  it "stores times as db format" do
    t = Time.now.utc
    expect(create_change(old_value: t).reload.old_value.sub(/\.\d+$/,'').sub(/ UTC$/, '')).to eq(t.strftime("%Y-%m-%d %H:%M:%S"))
  end

  it "stores dates as db format" do
    expect(create_change(old_value: Date.new(2012)).reload.old_value).to eq("2012-01-01")
  end

  it "stores booleans as db format" do
    expect(create_change(old_value: false).reload.old_value).to eq("f")
    expect(create_change(old_value: true).reload.old_value).to eq("t")
  end

  it "stores nil as nil" do
    expect(create_change(old_value: nil).reload.old_value).to be_nil
  end

  it "delegates create_at to event" do
    t = Time.now
    event = CIA::Event.new(created_at: t)
    change = CIA::AttributeChange.new(event: event)
    expect(change.created_at).to eq(event.created_at)
  end

  describe ".previous" do
    it "finds by id desc" do
      CIA::AttributeChange.delete_all
      a = create_change
      b = create_change
      expect(CIA::AttributeChange.previous).to eq([b,a])
    end
  end

  describe ".on_attribute" do
    it "finds with attribute" do
      a = create_change attribute_name: :xxx
      b = create_change attribute_name: :yyy
      expect(CIA::AttributeChange.on_attribute(:xxx).to_a).to eq([a])
    end
  end

  describe "enforcing presence of source" do
    it "requires a source when associated event requires a source" do
      event = CIA::Event.new { |event| event.id = 1 }
      allow(event).to receive(:source_must_be_present?).and_return(true)
      change = CIA::AttributeChange.new(event: event, attribute_name: 'awesomeness')

      expect(change.valid?).to be false
      expect(change.errors.full_messages).to match(["Source can't be blank"])
    end

    it "does not require a source when associated event does not" do
      event = CIA::Event.new { |event| event.id = 1 }
      allow(event).to receive(:source_must_be_present?).and_return(false)
      change = CIA::AttributeChange.new(event: event, attribute_name: 'awesomeness',
                                        source_type: 'ObscureType', source_id: 101)

      expect(change.valid?).to be true
    end
  end

  describe ".max_value_size" do
    it "is the width of the old/new column" do
      expect(CIA::AttributeChange.max_value_size).to eq(255)
    end
  end

  describe ".serialize_for_storage" do
    it "stores as json" do
      expect(CIA::AttributeChange.serialize_for_storage([["xxx"]]){}).to eq('[["xxx"]]')
    end

    it "calls the block to remove an item" do
      expect(CIA::AttributeChange.serialize_for_storage([["xxx"], ["x"*300], ["yyy"]]){ |array| array.delete_at(1); array  }).to eq('[["xxx"],["yyy"]]')
    end

    it "blows up if block fails to reduce size to prevent loops" do
      expect{
        CIA::AttributeChange.serialize_for_storage([["xxx"], ["x"*300], ["yyy"]]){ |array| array  }
      }.to raise_error(RuntimeError, 'The block did not reduce the size')
    end

    it "takes multibyte into account" do
      called = false
      CIA::AttributeChange.serialize_for_storage(["å" * 200]){ |array| called = true; "x" }
      expect(called).to be true
    end

    it "does not go crazy on multibytes" do
      called = false
      CIA::AttributeChange.serialize_for_storage(["å" * 100]){ |array| called = true; "x" }
      expect(called).to be false
    end
  end
end
