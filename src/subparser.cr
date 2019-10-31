require "./exceptions.cr" 
require "levenshtein"

module Phreak
	class Subparser
		protected property bindings : Array(Binding) = [] of Binding
		protected property fuzzy_bindings : Array(Binding) = [] of Binding
		protected property wildcard : Binding | Nil = nil

		private record Binding,
			word : String | Nil,
			long_flag : String | Nil,
			short_flag : Char | Nil,
			event : Proc(Subparser, String, Nil)

		protected property missing_arguments_handler : Proc(String, Nil)
		protected property unrecognized_arguments_handler : Proc(String, Nil)

		# Sets the maximum fuzzy finding distance allowed.
		setter max_fuzzy_distance = 3

		def initialize(@parent : Subparser | Nil)
			@missing_arguments_handler = ->(apex : String) {default_missing_arguments_handler apex}
			@unrecognized_arguments_handler = ->(name : String) {default_unrecognized_arguments_handler name}
		end
		
		# Binds a keyword or keywords to a callback.
		# 
		# Accepts any of these optional keyword types:
		# - word : A word. For example, "version" would translate to `cli version` on the command line.
		# - long_flag : A flag that is preceded by a double dash.
		# - short_flag : A character prefixed with a single dash. These can be stacked - to give an example,
		# 	`cli -Syu` on the command line will run the bound event for 'S', 'y', and 'u' on the root parser.
		#
		# **NOTE:**
		# Do **not** include prefix dashes in long_flag or short_flag -
		# They are inferred by Phreak. So, if you provide `long_flag: "--version"`,
		# the cli will repond to `----version`, with two dashes automatically added by 
		# Phreak. The same goes for short flags - if the desired flag is "-v", `short_flag`
		# should be set to 'v', not "-v".
		#
		# Another possible source of unexpected behaviour is short flag stacking. If two short flags in a stack
		# both require a parameter, Phreak will not throw an error by design. Instead, the event handlers for each
		# flag will be called in order left to right, and the parameters will be consumed first come first serve.
		# For example, if flag `-a` and `-b` both take a parameter, 
		# ```
		# cli -a PARAM1 -b PARAM2
		# ```
		# is equivalent to
		# ```
		# cli -ab PARAM1 PARAM2
		# ```
		# because `a` consumes PARAM1, then returned, which then let `b` consume PARAM2. If the user is aware of this
		# functionality, it can be very convinient. However, if they are not, it can lead to confusing side effects
		# that they might not be aware of.
		#
		# &block will be invoked whenever one of the keywords is detected in the parse loop.
		# The arguments provided are the `Parser` which called the block, as well the keyword
		# that triggered the event. The block may return either a new Subparser, generated from Parser.fork,
		# or nil. If a Subparser is returned, the next keyword will be parsed using that Subparser. This allows
		# for a stronger command structure.
		def bind(word : String | Nil = nil, long_flag : String | Nil = nil,
					short_flag : Char | Nil = nil, &block : Subparser, String -> Nil) : Nil
			@bindings.push Binding.new(word, long_flag, short_flag, block)
		end

		# Identical to bind, except the match for `word` or `long_flag` is fuzzy. These callbacks are
		# not considered until all else has failed.
		def fuzzy_bind(word : String | Nil = nil, long_flag : String | Nil = nil, &block : Subparser, String -> Nil) : Nil
			@fuzzy_bindings.push Binding.new(word, long_flag, nil, block)
		end

		# Creates a wildcard binding. This is more or less equivalent to calling next_token on the
		# root `Parser`, however you don't have to worry about catching an IndexError. Nothing will
		# stop you from calling grab multiple times, but a subparser will only keep track of the
		# final bound callback.
		def grab(&block : Subparser, String -> Nil) : Nil
			@wildcard = Binding.new(nil, nil, nil, block)
		end

		# Binds a block to a callback in the case that there are not enough arguments to continue parsing.
		# Note that this will only be called if Phreak runs out of arguments.
		# If your code invokes next_token on the root without assuring a token exists,
		# an InsufficientArgumentsException will be raised, but missing_args will not be
		# called.
		def missing_args(&block : String ->)
			@missing_arguments_handler = block
		end

		# By default, the missing exception handler just defers the error to its parent.
		# This allows for an error bubbling mechanism - if any of the subparsers above this one
		# on the chain have overridden the missing arguments handler, the exception will
		# be captured there, where it can be handled in whatever way the user intends. If the
		# user never defines a missing argument handler (via `missing_args`),
		# this error will continue to bubble, eventually reaching the Parser at the root.
		# The Parser is then able to define it's own functions for handling this error, either
		# letting the exception halt execution of the program, or by printing an error message.
		# By default, it just throws the error as of September 4th 2019.
		protected def default_missing_arguments_handler(apex : String)
			if parent = @parent
				parent.missing_arguments_handler.call apex
			else
				raise NilParentException.new
				return
			end
		end

		
		# Sets the handler block to yield to in the case of an unrecognized argument.
		# Provides the argument to the callback.
		def unrecognized_args(&block : String ->)
			@unrecognized_arguments_handler = block
		end

		# See the documentation for `default_missing_arguments_handler`
		protected def default_unrecognized_arguments_handler(name : String)
			if parent = @parent
				parent.unrecognized_arguments_handler.call name
			else
				raise NilParentException.new
				return
			end
		end

		# Accepts a raw argument and determines if it is a word, short flag, or long flag.
		# Once it's type is determined, this method runs the correct handler to call an event.
		# If it is malformed, a `MalformedTokenException` is raised.
		protected def process_token(token : String, root : Parser) : Nil
			# A wildcard defined with `Subparser#grab` will recieve the raw argument.
			raw = token

			if token.size == 0
				raise MalformedTokenException.new("Token is an empty string!")
			end
			
			prefix_dashes = 0

			#TODO: make less cryptic
			# This block just couns and strips up to two dashes from the left
			# side of the parameter.
			(0..Math.min(1, token.size - 1)).each do |i|
				if token[i] != '-'
					break
				end

				prefix_dashes += 1
			end

			token = token[prefix_dashes..-1]

			# If stripping between zero and two left dashes off the token made
			# it empty, it was either "-" or "--". Regardless, it's useless.
			if token.size == 0
				raise MalformedTokenException.new("Token is just dashes!")
			end

			# Note that the `handle_*something*` functions can all throw an
			# `InternalUnrecognizedTokenException` in the event that the token is unrecognized.
			# This begin-rescue block just catches that and bubbles the error up 
			# (see `Subparser#default_unrecognized_arguments_handler` for info).
			begin
				# This statement just chooses how to handle the token depending on what
				# type of argument it was - word, short flag, or long flag respectively.
				case prefix_dashes
				when 0 
					handle_name(root, word: token)
				when 1
					handle_chars(root, token)
				when 2
					# TODO: when an apex is reached, handle_name will call process_token (this)
					# for all remaining arguments at the apex level. However, if
					# a binding is not found, this will happen:
					# process_token:
					# 	handle_name:
					#   process_token (Because we were at an apex):
					#    handle_char/name (the next token):
					#     raise InternalUnrecognizedTokenException
					# the deeper process_token rescues that exception as expected, but
					# if **that** exception handler throws its own InternalUnrecognizedTokenException
					# (the root parser does this by default), then THAT exception gets
					# caught by the first call of process_token. However, in that shallower
					# context, `token` will be equal to the previous apex token! So
					# ultimately, THAT will be the exception that crashes the program,
					# but it will say the crash occurred when parsing the previous keyword
					# (the apex), which actually parsed just fine.
					#
					# Ugh.
					handle_name(root, long_flag: token)
				end
			rescue ex : InternalUnrecognizedTokenException
				if wildcard = @wildcard
					invoke_event(wildcard, raw, root)
				else
					@unrecognized_arguments_handler.call token

					# If the handler just called didn't abort execution, phreak will
					# just keep parsing
					if root.token_available?
						process_token(root.next_token, root)
					end
				end
			end
		end

		# Searches for a binding with a word or long_flag that match the argument.
		# Only one of word or long_flag should be a String, the other should be nil.
		# If there are no matches, an `InternalUnrecognizedTokenException` is raised.
		private def handle_name(root : Parser, word : String | Nil = nil, long_flag : String | Nil = nil) : Nil
			# Ensure that one and only one of word and long flag are defined
			if (word && long_flag) || (word == long_flag)
				raise MalformedHandleRequestException.new "Both word and long_flag are of the same type (both undefined, or both strings)! Only one should be defined."
			end

			# Check each binding to see if the assigned word matches
			@bindings.each do |binding|
				long_flag_match = long_flag && binding.long_flag == long_flag
				word_match = word && binding.word == word
				
				if word_match || long_flag_match
					# At this point, we are guaranteed to have a match, so we can strip the Nil type union off.
					match = (word_match ? word : long_flag).as String

					# Let's actually run the event, then! This also kicks off the nested events.
					invoke_event(binding, match, root)

					# We found a match, so there's no point continuing this loop.
					return
				end
			end

			best : Binding | Nil = nil
			min_distance : UInt8 = (2**8-1).to_u8

			# This code is messy and redundant. Unfortunately, there's very little I think I can do
			# to improve code quality here, as we have to refer to different properties on the record.
			if word
				@fuzzy_bindings.each do |binding|
					if keyword = binding.word
						if (dist = Levenshtein.distance(keyword, word)) < min_distance
							min_distance = dist.to_u8
							best = binding
						end
					end
				end
			elsif long_flag
				@fuzzy_bindings.each do |binding|
					if keyword = binding.long_flag
						if (dist = Levenshtein.distance(keyword, long_flag)) < min_distance
							min_distance = dist.to_u8
							best = binding
						end
					end
				end
			end

			if best && min_distance <= @max_fuzzy_distance
				if match = word ? best.word : best.long_flag
					invoke_event(best, match, root)
					return
				end
			end

			# If this point is reached, it means none of the bindings matched this word.
			raise InternalUnrecognizedTokenException.new "Unrecognized token `#{word}`!"
		end

		# Accepts a block of characters, identifying the bound event for each one and invoking them if
		# it exists.
		private def handle_chars(root : Parser, char_block : String) : Nil
			char_block.chars.each do |flag|
				found = false
				@bindings.each do |binding|
					if binding.short_flag == flag
						found = true
						invoke_event(binding, flag.to_s, root)
					end
				end

				if !found
					raise InternalUnrecognizedTokenException.new "Unrecognized token `#{flag}`!"
				end
			end
		end

		# Calls the bound event, checks if more bindings were requested on the subparser,
		# and if so executes them.
		private def invoke_event(binding : Binding, match : String, root : Parser)
			# If the word does match, we need to invoke the event. First, we'll create
			# a subparser to pass into that event, so that it can bind the next keyword
			# if desired.
			subparser = Subparser.new self

			binding.event.call(subparser, match)

			# Now that the event code has run, we want to check if any bindings were created
			# in the subparser we passed in.
			if subparser.bindings.size > 0 || subparser.fuzzy_bindings.size > 0 || subparser.wildcard
				# At least one event was created, which means that the cli is expecting another
				# token.
				begin
					next_token = root.next_token
					if next_token
						# If there was a token still available, we can call the subparser's `process_token`
						# method.
						subparser.process_token(next_token, root)
					end
				rescue ex : InsufficientArgumentsException
					subparser.missing_arguments_handler.call match
				end
			else
				# This branch in the code is reached if the subparser did not create any additional bindings -
				# In essence, we have reached a local maximum in the nesting of this command.
				#
				# If we return here, the stack will collapse back down to `Parser#begin_parsing`. This means
				# that if we have a binding structure like this:
				# a > crystal
				#  	b > build (consumes next_token to get filename)
				# 			c > --threads (consumes next_token to get threadcount)
			   # 			d > --time
				# and we run the command `crystal build test.cr --threads 1 --time, we would run into a problem -
				# the command would climb and climb until the apex (the level where `-threads` and `--time` are),
				# ultimately capturing the threads argument successfully. But, the stack would collapse, and the
				# --time argument would never get read. So, what we really want to do is create a loop instead
				# of returning. We will consume new arguments at the highest level available to us (our global
				# maximum). This means that time will be correctly read. Keep in mind that this loop is recursive!
				if root.token_available?  # This typecast is safe, as we just assured next_token (String | Nil) is not Nil
					next_token = root.next_token.to_s
					process_token(next_token, root)
				end
			end
		end
	end
end
