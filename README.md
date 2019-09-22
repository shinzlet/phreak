# Phreak
Phreak is a CLI builder in the style of Crystal's builtin OptionParser. It aims
to provide greater flexibility by integrating subcommands natively, all while
retaining a very simple callback based code style.

If you use Phreak in a project, please let me know! I'd love to see what you've
made, and would be happy to put your project in the [examples](##examples)
section. (My email address is in my github profile.)

## Table of contents
- [Features](##features)
- [Installation](##installation)
- [Examples](##examples)
- [Development](##development)
- [Contributing](##contributing)
- [Contributors](##contributors)

## Features
- [Basic flags](###basic-commands)
- [Subcommands](###subcommands)
- [Nested subcommands](###nested-subcommands)
- [Command types](###command-types)
- [Fuzzy matching](###fuzzy-matching)
- [Compound flags](###compound-flags)
- [Default actions](###default-actions)
- [Basic error handling](###basic-error-handling)
- [Error bubbling](###error-bubbling)
- [Planned features](##planned-features)

Much like OptionParser, Phreak makes registering commands incredibly easy:

### Basic commands
```crystal
require "phreak"

Phreak.parse! do
   # This will respond to the arguments "-a" or "--flag1"
   root.bind(short_flag: 'a', long_flag: "flag1") do
      puts "Someone called?"
   end
end
```

So, you've got all the familiar bells and whistles right there - I doubt you
came here for the standard bells and whistles, though. Let's get to the good
stuff.

### Subcommands
Phreak allows you to create clear, human-readable CLIs with ease, thanks to
subcommands.

```crystal
require "phreak"

Phreak.parse! do |root|
	root.bind(word: "throw") do |sub|
      # Responds to "./binary throw -p" or "subcommand throw --party"
		sub.bind(short_flag: 'p', long_flag: "party") do
			puts "Whoo!"
		end
	end

	root.bind(word: "info") do |sub|
      # Responds to "./binary info -d" or "subcommand info --dogs"
		sub.bind(short_flag: 'd', long_flag: "dogs") do
			puts "dogs are just incredible."
		end
	end
end
```

### Nested subcommands
Building on that more fluent subcommand syntax mentioned above, Phreak also lets
you create heirarchical commands (think `nmcli device wifi connect ...`, for
example).

```crystal
require "phreak"

Phreak.parse! do |root|
   root.bind(word: "wifi") do |wifi|
      wifi.bind(word: "status") do
         # Reponds to "nested wifi status"
      end

      wifi.bind(word: "set") do |set|
         set.bind(word: "disabled", short_flag: 'd') do
            # Responds to "nested wifi set disabled" or
            # "nested wifi set -d"
         end
      end
   end
end
```

### Command types
Phreak allows you to create three primary types of commands:
- Short flags (e.g. `ls -a`)
- Long flags (e.g. `ls --all`)
- Words (e.g. `git push`)

You can alias one of each to a command in one line, too:
```crystal
require "phreak"

Phreak.parse! do |root|
   root.bind(short_flag: 'a', long_flag: "all", word: "all") do
      # Responds to -a, --all, or 'all'
   end
end
```

### Fuzzy matching
Phreak allows you to fuzzy match commands as desired! For example:

```crystal
require "phreak"

Phreak.parse! do |root|
   root.fuzzy_bind(word: "enable") do |sub, match|
      # Responds to words close to enable - enab, enablt, for example
      puts "Fuzzy matched #{match}"
   end
end
```

### Compound flags
Many CLIs allow flags to be stacked to run several processes in a row. For
example, `ls -al` tells ls to print **a**ll files in a **l**ong format.

```crystal
require "phreak"

Phreak.parse! do |root|
   root.bind(short_flag: 'a') do
      puts "A!"
   end

   root.bind(short_flag: 'b') do
      puts "B!"
   end

   root.bind(short_flag: 'c') do
      puts "C!"
   end
end
```

Given the above program, compiled to *binary*:

```sh
$ ./binary -abc     # Prints "A!B!C!"
$ ./binary -ac      # Prints "A!C!"
$ ./binary -bbb     # Prints "B!"
```

### Default actions
In some cases, CLIs should have a default behaviour only when no arguments are
provided. Phreak makes that easy:

```crystal
require "phreak"

Phreak.parse! do |root|
   root.default do
      puts "no arguments provided"
   end
end
```

### Basic error handling
Phreak makes it easy to detect incorrect usage of your CLI.

```crystal
require "phreak"

Phreak.parse! do |root|
   root.bind(word: "say") do |sub|
		sub.bind(word: "hi") do
			puts "Hi!"
		end
   end

	root.default do
		puts "No arguments provided"
	end

   root.missing_args do |apex|
      puts "Missing an argument after #{apex}"
   end

   root.unrecognized_args do |arg|
      puts "Unrecognized argument: #{arg}"
   end
end
```

Here, if we run `./binary say`, the `missing_args` handler will be called. If we
ran `./binary say goodbye`, the `unrecognized_args` handler would be run.
If we don't provide an argument at all, the `default` handler is called.
Finally, if we correctly invoke `./binary say hi`, the CLI will print out "Hi!"


### Error bubbling
Due to the way that Phreak works, you can actually bind a `missing_args` or
`unrecognized_args` handler to any part of a nested command. For example:

```crystal
require "phreak"

Phreak.parse! do |root|
   root.bind(word: "say") do |sub|
		sub.bind(word: "hi") do
			puts "Hi!"
		end

      sub.bind(word: "hello") do |sub|
         sub.bind(word: "tomorrow") do
            puts "Sure thing!"
         end

         sub.missing_args do
            puts "Hello!"
         end

         sub.unrecognized_args do |arg|
            puts "When's #{arg}?"
         end
      end

		sub.unrecognized_args do |arg|
			puts "I can't say #{arg}!"
		end
   end
end
```

Let's see what happens in a few example inputs:

`./binary say hi`
- The binding for 'say' is recognized, and a `Subparser` (the `sub` variable) is created.
- The binding for 'hi' is invoked, and the program terminates.

`./binary say goodbye`
- The binding for 'say' is recognized.
- None of the bindings match 'goodbye', so the `unrecognized_args` handler on `say` is invoked.

`./binary say hello`
- The binding for 'say' is recognized.
- The binding for 'hello' is recognized.
- We tell the `Subparser` to bind the word 'tomorrow' to a callback, but we're
    out of keywords!
- The `missing_args` handler is invoked in the scope of the 'hello' binding.
- The handler says hello!

The lattermost case may seem very similar to the `default` handler, but there
are some important differences. `default` is only ever called if the size of the
arguments array is zero (there are absolutely no arguments). It can also only be
bound to the root `Parser` (which is actuallly a `Subparser+`).

Errors also bubble - that is, if we had not defined a `missing_args` handler on
'hello', Phreak would then try to invoke a `missing_args` event on 'say', then
on the root subparser. If no handlers are found on the traversal back up, an
exception is raised.

## Planned features
- Autogenerated documentation (at compile time)
- Autogenerated fish completions
- Typo fix suggestions (did you mean 'commit'?)

## Installation

1. Add phreak to your `shard.yml`:

   ```yaml
   dependencies:
     phreak:
       github: shinzlet/phreak
   ```

2. Run `shards install`

## Examples
I wrote [sd](https://github.com/shinzlet/sd) using Phreak! It was a great case
study of what features I needed to add to get a truly flexible CLI builder.

## Development
Please see [phreak's vivisection](vivisection.md) for an overview of how Phreak
works under the hood!

## Contributing

1. Fork it (<https://github.com/your-github-user/./fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [shinz](https://github.com/shinzlet) - creator and maintainer
