require "./subparser.cr"

module Phreak
	# The internal master parsing class. This is where everything is initially kicked off.
	class Parser < Subparser
		def initialize(@args : Array(String))
		end

		# Starts the parsing chain.
		protected def begin_parsing : Nil
			while @args.size > 0
				process_token(next_token, self)
			end
		end

		# Returns the next argument in the stack. May raise an exception if `@args.size == 0`
		def next_token : String | Nil
			return @args.delete_at(0)
		end
	end
end
