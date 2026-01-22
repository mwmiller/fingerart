# Fingerart

[![Hex.pm](https://img.shields.io/hexpm/v/fingerart.svg)](https://hex.pm/packages/fingerart)
[![Hex Docs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/fingerart)

Generate OpenSSH-style fingerprint random art (The Drunken Bishop algorithm) in Elixir.

## Installation

The package can be installed by adding `fingerart` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fingerart, "~> 0.1.0"}
  ]
end
```

## Usage

You can generate fingerprint art from either a binary hash or a standard SSH fingerprint string.

### From a binary hash

```elixir
# A 128-bit hash (MD5-style length)
binary = <<252, 148, 176, 193, 229, 176, 152, 124, 88, 67, 153, 118, 151, 238, 159, 183>>
IO.puts Fingerart.generate(binary)
```

### From a fingerprint string

```elixir
fingerprint = "fc:94:b0:c1:e5:b0:98:7c:58:43:99:76:97:ee:9f:b7"
IO.puts Fingerart.generate(fingerprint, "my-key")
```

### Output Example

```text
+---[my-key]------+
|       .=o.  .   |
|     . *+*. o    |
|      =.*..o     |
|       o + ..    |
|        S o.     |
|         o  .    |
|          .  . . |
|              o .|
|               E.|
+-----------------+
```

## Documentation

Docs can be found at [https://hexdocs.pm/fingerart](https://hexdocs.pm/fingerart).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.