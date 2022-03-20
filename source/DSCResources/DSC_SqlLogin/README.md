# Description

The `SqlLogin` DSC resource manages SQL Server logins
for a SQL Server instance.

## Requirements

* Target machine must be running Windows Server 2012 or later.
* Target machine must be running SQL Server Database Engine 2012 or later.
* When the `LoginType` of `'SqlLogin'` is used, then the login authentication
  mode must have been set to `Mixed` or `Normal`. If set to `Integrated`
  and error will be thrown.
* The `LoginMustChangePassword` parameter is only valid on a `SqlLogin`
  where the `LoginType` parameter is set to `'SqlLogin'`.
* The `LoginMustChangePassword` parameter can **not** be used to change
  this setting on a pre-existing `SqlLogin` - This parameter can only
  be used when creating a new `SqlLogin` and where subsequent updates will
  not be applied or, alternatively, when the desired state will not change (for example,
  where `LoginMustChangePassword` is initially set to `$false` and will always
  be set to `$false`).
* The `LoginPasswordPolicyEnforced` parameter cannot be set to `$false` if
  the parameter `LoginPasswordExpirationEnabled` is set to `$true`, or if
  the property `PasswordExpirationEnabled` of the login has already been
  set to `$true` by other means. It will result in the error
  _"The CHECK_EXPIRATION option cannot be used when CHECK_POLICY is OFF"_.
  If the parameter `LoginPasswordPolicyEnforced` is set to to `$false` then
  `LoginPasswordExpirationEnabled` must also be set to `$false`.

## Known issues

All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+SqlLogin).
