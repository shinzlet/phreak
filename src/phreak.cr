require "./parser.cr"
require "./subparser.cr"

# Phreak is a library for creating CLIs in the style of Crystal's built in OptionParser,
# but with much more flexibility.
module Phreak
	extend self

	# Equivalent to invoking `Phreak::parse` with args = ARGV.
	def self.parse!(&block : Subparser -> Nil)
		parse ARGV do |sp|
			block.call sp
		end
	end

	# Initializes a parser, and yields to a setup block with the created
	# subparser.
	def self.parse(args : Array(String), &block : Subparser -> Nil)
		# First, we create a master parser. See the documenation of `Phreak::Parser`
		# for more details on what it is, and why it's an extended subparser.
		parser = Parser.new
		# Now, we call the setup block - this is where the CLI can create bindings
		# to the parser instance.
		yield parser
		# Finally, we can actually parse the arguments.
		parser.parse args
	end
end
