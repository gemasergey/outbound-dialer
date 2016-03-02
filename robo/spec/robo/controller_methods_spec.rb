require 'spec_helper'

module Robo
  describe ControllerMethods do
    describe "mixed in to a CallController" do

      class TestController < Adhearsion::CallController
        include Robo::ControllerMethods
      end

      let(:mock_call) { double 'Call' }

      subject do
        TestController.new mock_call
      end

      describe "#greet" do
        it "greets with the correct parameter" do
          subject.should_receive(:play).once.with("Hello, Luca")
          subject.greet "Luca"
        end
      end

    end
  end
end
