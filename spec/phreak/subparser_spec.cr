require "../../src/*"
require "spec"

describe Phreak::Subparser do
	describe "#bind" do
		it "correctly binds to flags" do
			count = 0

			Phreak.parse("test --test -t".split(" ")) do |root|
				root.bind(word: "test", long_flag: "test", short_flag: 't') do
					count += 1
				end
			end

			count.should eq 3
		end

		it "raises an UnrecognizedTokenException when token not recognized" do
			expect_raises(Phreak::UnrecognizedTokenException) do
				Phreak.parse("foo".split(" ")) do |root|
					root.bind(word: "bar") do
						raise Exception.new("Should not have reached this point!")
					end
				end
			end
		end
	end

	describe "#fuzzy_bind" do
		it "correctly fuzzy matches" do
			recognized = 0
			unrecognized = 0

			Phreak.parse("fuzzy fuzz fuz fu f".split(" ")) do |root|
				root.fuzzy_bind(word: "fuzzy") do
					recognized += 1
				end

				root.unrecognized_args do
					unrecognized += 1
				end
			end

			recognized.should eq 4
			unrecognized.should eq 1
		end
	end

	describe "#grab" do
		it "gets a wildcard token" do
			Phreak.parse("token".split(" ")) do |root|
				root.grab do |sub, token|
					token.should eq "token"
				end
			end
		end
	end

	describe "#missing_args" do
		it "calls back when an argument that does not exist is accessed" do
			ran = false

			Phreak.parse(["subcommand"]) do |root|
				root.bind(word: "subcommand") do |sub|
					sub.grab do
					end
				end

				root.missing_args do
					ran = true
				end
			end

			ran.should eq true
		end
	end

	describe "#unrecognized_args" do
		it "calls back when an unrecognized argument is encountered" do
			count = 0

			Phreak.parse("foo bar baz foo".split(" ")) do |root|
				root.bind(word: "foo") do
				end

				root.unrecognized_args do
					count += 1
				end
			end

			count.should eq 2
		end
	end
end
