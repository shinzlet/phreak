require "./exceptions.cr"

module Phreak
	class Subparser
		@bindings : Array(Binding) = [] of Binding

		private record Binding,
			long_flag : String | Nil,
			short_flag : String | Nil,
			word : String | Nil,
			event : Proc(Subparser, Nil)
		
		def initialize(@root : Parser | Nil)
		end
		
		# Binds a keyword or keywords to a callback.
		# 
		# Accepts any of these optional keyword types:
		# - word : A word. For example, "version" would translate to `cli version` on the command line.
		# - long_flag : A flag that is preceded by a double dash
		# - short_flag : A character prefixed with a single dash
		# **NOTE:**
		# Do **not** include prefix dashes in long_flag or short_flag -
		# They are inferred by Phreak. So, if you provide `long_flag: "--version"`,
		# the cli will repond to `----version`, with two dashes automatically added by 
		# Phreak. The same goes for short flags - if the desired flag is "-v", `short_flag`
		# should be set to "v", not "-v".
		def bind(word : String | Nil = nil, long_flag : String | Nil = nil,
					short_flag : String | Nil = nil, &block : Subparser ->)
			if root = @root

			else
				raise NilRootException.new("Cannot bind - root is nill, likely due to a Subparser initialized on it's own.")
			end
		end

		def process_token(token : String)

		end
	end
end
