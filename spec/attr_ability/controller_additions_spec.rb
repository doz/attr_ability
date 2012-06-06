require 'spec_helper'

describe AttrAbility::ControllerAdditions do
  class TestController < ActionController::Base
  end

  it "reveals own cancan_resource_class" do
    TestController.new.cancan_resource_class.should == AttrAbility::Controller::ControllerResource
  end
end
