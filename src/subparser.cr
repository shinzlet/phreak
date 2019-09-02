require "./exceptions.cr"

module Phreak
	class Subparser
		protected property bindings : Array(Binding) = [] of Binding

		private record Binding,
			word : String | Nil,
			long_flag : String | Nil,
			short_flag : Char | Nil,
			accepts_parameter : Bool,
			event : Proc(Subparser, String, Nil)

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
		# should be set to 'v', not "-v".
		#  
		# accepts_parameter **MUST** be set to true if it is possible for the bound event to 
		# use a paremeter.
		# 
		# &block will be invoked whenever one of the keywords is detected in the parse loop.
		# The arguments provided are the `Parser` which called the block, as well the keyword
		# that triggered the event. The block may return either a new Subparser, generated from Parser.fork,
		# or nil. If a Subparser is returned, the next keyword will be parsed using that Subparser. This allows
		# for a stronger command structure.
		def bind(word : String | Nil = nil, long_flag : String | Nil = nil,
					short_flag : Char | Nil = nil, accepts_parameter : Bool = false, &block : Subparser, String -> Nil) : Nil
			@bindings.push Binding.new(word, long_flag, short_flag, accepts_parameter, block)
		end

		# Accepts a raw argument and determines if it is a word, short flag, or long flag.
		# Once it's type is determined, this method runs the correct handler to call an event.
		# If it is malformed, a `MalformedTokenException` is raised.
		protected def process_token(token : String, root : Parser) : Nil
			if token.size == 0
				raise MalformedTokenException.new("Token is an empty string!")
			end
			
			prefix_dashes = 0

			#TODO: make less cryptic
			(0..Math.min(1, token.size - 1)).each do |i|
				if token[i] != '-'
					break
				end

				prefix_dashes += 1
			end

			token = token[prefix_dashes..-1]

			if token.size == 0
				raise MalformedTokenException.new("Token is just dashes!")
			end

			case prefix_dashes
			when 0, 2
				handle_name(token, root)
			when 1
				handle_chars(token, root)
			end
		end

		# Searches for a binding with a word or long_flag that match the argument.
		# Only one of word or long_flag should be a String, the other should be nil.
		# If there are no matches, an `UnrecognizedTokenException` is raised.
		private def handle_name(word : String | Nil, long_flag : String | Nil, root : Parser) : Nil
			# Ensure that one and only one of word and long flag are defined
			if (word && long_flag) || (word == long_flag)
				raise MalformedHandleRequestException.new "Both word and long_flag are of the same type (both undefined, or both strings)! Only one should be defined."
			end

			# Check each binding to see if the assigned word matches
			@bindings.each do |binding|
				long_flag_match = long_flag && binding.long_flag == long_flag
				word_match = word && binding.word == word
				
				if word_match || long_flag_match
					# If the word does match, we need to invoke the event. First, we'll create
					# a subparser to pass into that event, so that it can bind the next keyword
					# if desired.
					subparser = Subparser.new root
					binding.event.call(subparser, word)

					# Now that the event code has run, we want to check if any bindings were created
					# in the subparser we passed in.
					if subparser.bindings.size > 0
						# At least one event was created, which means that the cli is requesting that
						# the next word be equal to something.
						next_token = root.next_token
						if next_token
							# If there was a token still available, we can call the subparser's `process_token`
							# method.
							subparser.process_token(next_token, root)
						end
					end

					# We found a match, so there's no point continuing this loop.
					return
				end
			end

			# If this point is reached, it means none of the bindings matched this word.
			raise UnrecognizedTokenException.new "Unrecognized token `#{word}`!"
		end

		private def handle_chars(char_block : String, root : Parser) : Nil
			puts char_block
		end
	end
end
