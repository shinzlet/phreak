module Phreak
	class Subparser
		def initialize
		end

		def bind(key : String, &block : -> Nil)
			yield
		end

		def process_token(token : String)

		end
	end
end
