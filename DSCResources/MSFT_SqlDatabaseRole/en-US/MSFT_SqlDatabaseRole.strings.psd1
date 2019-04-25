ConvertFrom-StringData @'
    GetDatabaseRole = Getting current role(s) for the user '{0}' of the database '{1}' on the instance '{2}'.
    DatabaseNotFound = The database '{0}' does not exist.
    RoleNotFound = The role '{0}' does not exist in the database '{1}'.
    LoginNotFound = The login '{0}' does not exist on the instance.
    IsMember = The login '{0}' is a member of the role '{1}' in the database '{2}'.
    IsNotMember = The login '{0}' is not a member of the role '{1}' in the database '{2}'.
    LoginIsNotUser = The login '{0}' is not a user in the database '{1}'.
    AddingLoginAsUser = Adding the login as a user of the database.
    FailedToAddUser = Failed to add the login '{0}' as a user of the database '{1}'.
    AddUserToRole = Adding the user (login) '{0}' to the role '{1}' in the database '{2}'.
    FailedToAddUserToRole = Failed to add the user {0} to the role {1} in the database {2}.
    DropUserFromRole = Removing the user (login) '{0}' from the role '{1}' in the database '{2}'.
    FailedToDropUserFromRole = Failed to remove the login {0} from the role {1} in the database {2}.
    TestingConfiguration = Determines if the the user '{0}' of the database '{1}' on the instance '{2}' is a member of the desired role(s).
    InDesiredState = The user '{0}' of the database '{1}' is member of the specified role(s).
    NotInDesiredStateAbsent = Expected the user '{0}' to not be a member of the specified role(s) in the database '{1}', but the user was member of at least one of the roles.
    NotInDesiredStatePresent = Expected the user '{0}' to be a member of the specified role(s) in the database '{1}', but the user was not a member of at least one of the roles.
'@
