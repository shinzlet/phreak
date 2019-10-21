require "spec"
require "../src/*"


describe Phreak::Parser do
	describe "#next_token" do
		it "returns the next token in the argument list" do
			Phreak.parse("arg1 arg2".split(" ")) do |root|
				root.next_token.should eq "arg1"
				root.next_token.should eq "arg2"
			end
		end
	end
end
