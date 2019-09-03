require "./subparser.cr"

module Phreak
	# The internal master parsing class. This is where everything is initially kicked off.
	class Parser < Subparser
		@default_action_handler : Proc(Void) | Nil = nil

		def initialize(@args : Array(String))
			@insufficient_arguments_handler = ->(apex : String) do
				raise InsufficientArgumentsException.new "Insufficient arguments provided after keyword '#{apex}', and no handlers specified."
			end
		end

		# Starts the parsing chain. If there are no arguments to parse, the default action handler will be called.
		protected def begin_parsing : Nil
			if @args.size == 0
				if handler = @default_action_handler
					handler.call
				end
			else
				while @args.size > 0
					process_token(next_token, self)
				end
			end
		end

		# Returns the next argument in the stack. May raise an exception if `@args.size == 0`
		def next_token : String | Nil
			@args.delete_at(0)
		end

		def token_available? : Boolean
			@args.size > 0
		end

		def default(&block : Proc(Void))
			@default_action_handler = block
		end
	end
end
