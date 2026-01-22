# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-22

### Added
- Initial implementation of the "Drunken Bishop" algorithm for OpenSSH-style random art.
- `Fingerart.generate/2` to create visual fingerprints from binaries or SSH key strings.
- Support for multiple output formats:
    - `:text` (default): ASCII art for terminals.
    - `:html`: Wrapped in `<pre>` tags with semantic spans.
    - `:svg`: Scalable vector graphics for web display.
- Color support via the `:color` option (ANSI for text, CSS for HTML, fill attributes for SVG).
- Comprehensive documentation and examples.