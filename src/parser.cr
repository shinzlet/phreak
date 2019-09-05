require "./subparser.cr"

module Phreak
	# The internal master parsing class. This is where everything is initially kicked off.
	class Parser < Subparser
		@default_action_handler : Proc(Void)

		def initialize(@args : Array(String))
			@insufficient_arguments_handler = ->(apex : String) do
				raise InsufficientArgumentsException.new "Insufficient arguments provided after keyword '#{apex}', and no handlers specified."
			end

			@default_action_handler = ->() do
				raise NoArgumentsException.new "No arguments were supplied!"
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

		# Returns the next argument in the stack. May raise an exception if `@args.size == 0`
		def next_token : String | Nil
			@args.delete_at(0)
		end

		def token_available? : Bool
			@args.size > 0
		end

		def default(&block : Proc(Void))
			@default_action_handler = block
		end
	end
end
