require "./parser.cr"
require "./subparser.cr"
require "./root_parser.cr"

# Phreak is a library for creating CLIs in the style of Crystal's built in OptionRootParser,
# but with much more flexibility.
module Phreak
  extend self
  VERSION = "0.1.0"

  # Equivalent to invoking `Phreak::parse` with args = ARGV.
  def self.parse!(&block : RootParser -> Nil) : Nil
    parse ARGV do |root|
      block.call root
    end
  end

  # Initializes a parser, and yields to a setup block with the created
  # subparser.
  def self.parse(args : Array(String), &block : RootParser -> Nil) : Nil
    # First, we create a master parser. See the documenation of `Phreak::RootParser`
    # for more details on what it is, and why it's an extended subparser.
    parser = RootParser.new args
    # Now, we call the setup block - this is where the CLI can create bindings
    # to the parser instance.
    yield parser
    # Finally, we can actually parse the arguments.
    parser.begin_parsing
  end

  # Creates a reusable instance of `Parser`. This is opposed to other
  # class methods on Phreak, which are single-use. As a note, this
  # can also be done using Parser.new, but using this method is
  # preferred style for consistency.
  def self.create_parser(&block : RootParser -> Nil) : Parser
    Parser.new(block)
  end
end
