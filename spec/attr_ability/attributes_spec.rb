require 'spec_helper'

describe AttrAbility::Attributes do
  describe "#normalize" do
    def normalize(attributes)
      AttrAbility::Attributes.new.send(:normalize, attributes)
    end

    it "normalizes array of attributes" do
      normalize([:a, :b, :c]).should == {"a" => true, "b" => true, "c" => true}
    end

    it "normalizes attribute with values" do
      normalize([a: [1, 2]]).should == {"a" => ["1", "2"]}
    end

    it "normalizes mix of attributes and values" do
      normalize([:a, :b, :c => [:d, :e], :f => [:g, :h]]).should == {"a" => true, "b" => true, "c" => ["d", "e"], "f" => ["g", "h"]}
    end
  end

  describe "#add" do
    before(:each) do
      @attributes = AttrAbility::Attributes.new
      @attributes.add [:a, :b, :c => [:d, :e]]
    end

    it "adds new attributes" do
      @attributes.add [:f, :g, :h => [1, 2]]
      @attributes.attributes.should == {"a" => true, "b" => true, "c" => ["d", "e"], "f" => true, "g" => true, "h" => ["1", "2"]}
    end

    it "merges attribute names" do
      @attributes.add [:b, :c]
      @attributes.attributes.should == {"a" => true, "b" => true, "c" => true}
    end

    it "merges attribute values" do
      @attributes.add [b: [1, 2], c: [:e, :f], g: [1, 2]]
      @attributes.attributes.should == {"a" => true, "b" => true, "c" => ["d", "e", "f"], "g" => ["1", "2"]}
    end

    it "merges with another attributes" do
      attributes = AttrAbility::Attributes.new
      attributes.add [:a, :f, :b => [1, 2], :c => [:e, :f], :g => [1, 2]]
      @attributes.add(attributes)
      @attributes.attributes.should == {"a" => true, "b" => true, "c" => ["d", "e", "f"], "f" => true, "g" => ["1", "2"]}
    end
  end

  describe "#allow?" do
    before(:each) do
      @attributes = AttrAbility::Attributes.new
      @attributes.add [:a, :b, :c => [:d, :e]]
    end

    it "allows attribute with any value" do
      @attributes.allow?(:a, :b).should be_true
    end

    it "allows attribute with specified value" do
      @attributes.allow?(:c, :d).should be_true
    end

    it "doesn't allow unspecified attribute" do
      @attributes.allow?(:g, 1).should be_false
    end

    it "doesn't allow attribute with unspecified value" do
      @attributes.allow?(:c, 1).should be_false
    end
  end
end