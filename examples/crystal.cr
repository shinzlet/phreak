# Crystal's command line interface (as seen in `$ crystal build`) is
# supposedly built on top of the OptionParser module. However, investigating
# it shows that it's a bit of a workaround - subcommands are parsed manually,
# and only flags are parsed with OptionParser. By using Phreak, we can implement
# the entire CLI in no time at all.

require "phreak"

Phreak.parse! do |parser|
	parser.bind(word: "build") do |sub|
		begin
			filename = parser.next_token
			puts "building #{filename}"
		rescue ex : IndexError
			abort "No filename provided!"
		end

		sub.bind(long_flag: "time", short_flag: 't') do |sub|
			puts "with timing enabled"
		end

		sub.bind(long_flag: "threads") do |sub|
			begin
				threadcount = parser.next_token.to_i32
				puts "and using #{threadcount} threads"
			rescue exc : IndexError
				abort "Number of threads not provided!"
			end
		end

		parser.insufficient_arguments do |apex|
			puts "insuff"
		end
	end

	parser.bind(word: "play") do |sub|
		puts "play"
	end
end
