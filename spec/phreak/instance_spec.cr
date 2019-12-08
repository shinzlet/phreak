require "../../src/*"
require "spec"

describe Phreak do
  describe "#create_parser" do
    it "Allows a parser to be reused" do
      # Keep track of the number of times the endpoint
      # executes.
      count = 0

      parser = Phreak.create_parser do |root|
        root.bind(word: "endpoint") do |sub|
          count += 1
        end
      end

      (1..5).each do |x|
        parser.parse(["endpoint"])
        count.should eq x
      end
    end
  end
end
