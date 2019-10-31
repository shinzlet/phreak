require "../../src/*"
require "spec"

describe Phreak do
	describe "#parse" do
		it "correctly reaches a multilevel endpoint" do
			reached = false

			Phreak.parse("alpha -g l".split(" ")) do |root|
				root.bind(word: "alpha") do |sub|
					sub.bind(short_flag: 'g') do |sub|
						sub.bind(word: "l") do |sub|
							reached = true
						end
					end
				end
			end

			reached.should eq true
		end

		it "Correctly executes a flag stack" do
			flags = [] of Char

			Phreak.parse("-xyz".split(" ")) do |root|
				root.bind(short_flag: 'x') do |sub|
					flags.push 'x'
				end

				root.bind(short_flag: 'y') do |sub|
					flags.push 'y'
				end

				root.bind(short_flag: 'z') do |sub|
					flags.push 'z'
				end
			end

			flags.should eq ['x', 'y', 'z']
		end
	end
end
