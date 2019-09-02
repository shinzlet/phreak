require "./parser.cr"
require "./subparser.cr"

# Phreak is a library for creating CLIs in the style of Crystal's built in OptionParser,
# but with much more flexibility.
module Phreak
	extend self
	VERSION = "0.1.0"

	# Equivalent to invoking `Phreak::parse` with args = ARGV.
	def self.parse!(&block : Parser -> Nil) : Nil
		parse ARGV do |sp|
			block.call sp
		end
	end

	# Initializes a parser, and yields to a setup block with the created
	# subparser.
	def self.parse(args : Array(String), &block : Parser -> Nil) : Nil
		# First, we create a master parser. See the documenation of `Phreak::Parser`
		# for more details on what it is, and why it's an extended subparser.
		parser = Parser.new args
		# Now, we call the setup block - this is where the CLI can create bindings
		# to the parser instance.
		yield parser
		# Finally, we can actually parse the arguments.
		parser.begin_parsing
	end
end
