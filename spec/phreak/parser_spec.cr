require "spec"
require "../../src/*"

describe Phreak::Parser do
  describe "#next_token" do
    it "returns the next token in the argument list" do
      Phreak.parse("arg1 arg2".split(" ")) do |root|
        root.next_token.should eq "arg1"
        root.next_token.should eq "arg2"
      end
    end
  end

  describe "#token_available?" do
    it "returns true if a token is available" do
      executed = false

      Phreak.parse("token".split(" ")) do |root|
        executed = true

        root.token_available?.should eq true

        root.unrecognized_args { }
      end

      executed.should eq true
    end
  end

  describe "#default" do
    it "runs when no arguments are provided" do
      ran = false

      Phreak.parse([] of String) do |root|
        root.default do
          ran = true
        end
      end

      ran.should eq true
    end
  end
end
