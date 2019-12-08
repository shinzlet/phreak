require "./subparser.cr"

module Phreak
  # The internal master parsing class. This is where everything is initially kicked off.
  class RootParser < Subparser
    @default_action_handler : Proc(Void)

    def initialize(@args : Array(String))
      @missing_arguments_handler = ->(apex : String) do
        raise InsufficientArgumentsException.new "Insufficient arguments provided after keyword '#{apex}', and no handlers specified."
      end

      @unrecognized_arguments_handler = ->(name : String) do
        raise UnrecognizedTokenException.new "Unrecognized token '#{name}' encountered, with no unrecognized argument handlers specified."
      end

      @default_action_handler = ->do
        # Do nothing
      end
    end

    # Starts the parsing chain. If there are no arguments to parse, the default action handler will be called.
    protected def begin_parsing : Nil
      if @args.size == 0
        @default_action_handler.call
      else
        process_token(next_token, self)
      end
    end

    # Returns the next token, if available. Will raise an exception if `@args.size == 0`
    def next_token : String | Nil
      # If there isn't a token, throw an exception
      raise InsufficientArgumentsException.new unless token_available?
      # This just returns the first thing in the args array
      @args.delete_at(0)
    end

    # Returns true if there is at least one token remaining to be parsed.
    def token_available? : Bool
      @args.size > 0
    end

    # Yields to a callback if `Phreak::parse` is called with no arguments.
    def default(&block : Proc(Void))
      @default_action_handler = block
    end
  end
end
