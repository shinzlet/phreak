module Phreak
	class MalformedTokenException < Exception
	end

	class UnrecognizedTokenException < Exception
	end

	class MalformedHandleRequestException < Exception
	end

	class InsufficientArgumentsException < Exception
	end
	
	class NilParentException < Exception
	end

	class NoArgumentsException < Exception
	end
end
