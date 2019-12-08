require "./subparser.cr"

module Phreak
  # This class serves as a reusable form of `Phreak.parse`. This allows
  # for a variety of uses, such as more readable code, complex interpreters,
  # and even text adventure games.
  class Parser
    @block : Proc(RootParser, Nil)

    def initialize(@block)
    end

    def parse!
      parse(ARGV)
    end

    def parse(args : Array(String))
      Phreak.parse(args) do |root|
        @block.call root
      end
    end
  end
end
