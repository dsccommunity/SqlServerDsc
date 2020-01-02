# Change log for SqlServerDsc

## Unreleased

- Changes to SqlServerDsc
  - Add .gitattributes file to checkout file correctly with CRLF.
  - Updated .vscode/analyzersettings.psd1 file to correct use PSSA rules
    and custom rules in VS Code.
  - Fix hashtables to align with style guideline ([issue #1437](https://github.com/PowerShell/SqlServerDsc/issues/1437)).
- Changes to SqlServerMaxDop
  - Fix line endings in code which did not use the correct format.
- SqlAlwaysOnService
  - The integration test has been temporarily disabled because when
    the cluster feature is installed it requires a reboot on the
    Windows Server 2019 build worker.
- SqlDatabaseRole
  - Update unit test to have the correct description on the `Describe`-block
    for the test of `Set-TargetResource`.
- SqlServerRole
  - Add support for nested role membership ([issue #1452](https://github.com/dsccommunity/SqlServerDsc/issues/1452))
  - Removed use of case-sensitive Contains() function when evalutating role membership.
    ([issue #1153](https://github.com/dsccommunity/SqlServerDsc/issues/1153))
  - Refactored mocks and unit tests to increase performance. ([issue #979](https://github.com/dsccommunity/SqlServerDsc/issues/979))

### Fixed

- SqlAlwaysOnService
  - When failing to enable AlwaysOn the resource should now fail with an
    error ([issue #1190](https://github.com/dsccommunity/SqlServerDsc/issues/1190)).
