# Phreak

Phreak is a CLI builder in the style of Crystal's builtin OptionParser. It aims
to provide greater flexibility by integrating subcommands natively, all while
retaining a very simple callback based code style.

Note that, at the moment, Phreak's syntax may be subject to change.

## Installation

1. Add phreak to your `shard.yml`:

   ```yaml
   dependencies:
     phreak:
       github: shinzlet/phreak
   ```

2. Run `shards install`

## Usage

Check out [examples](examples.md) for more demonstrations of how Phreak can be
implemented into your project.

```crystal
require "phreak"
```

## Development

Please see [phreak's vivisection](vivisection.md)

## Contributing

1. Fork it (<https://github.com/your-github-user/./fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [shinz](https://github.com/shinzlet) - creator and maintainer
