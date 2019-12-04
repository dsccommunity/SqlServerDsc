# Change log for SqlServerDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SqlServerDsc
  - Added automatic release with a new CI pipeline.

### Changed

- SqlServerDsc
  - Add .gitattributes file to checkout file correctly with CRLF.
  - Updated .vscode/analyzersettings.psd1 file to correct use PSSA rules
    and custom rules in VS Code.
  - Fix hashtables to align with style guideline ([issue #1437](https://github.com/PowerShell/SqlServerDsc/issues/1437)).
- SqlServerMaxDop
  - Fix line endings in code which did not use the correct format.

### Deprecated

- None

### Removed

- None

### Fixed

- None

### Security

- None
