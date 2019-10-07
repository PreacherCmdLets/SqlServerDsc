# Localized resources for MSFT_SqlServerAgentNotification

ConvertFrom-StringData @'
    GetSqlOpAlerts = Getting SQL Agent Operator's Alerts.
    SqlAgentOpPresent = SQL Agent Operator '{0}' is present.
    SqlAgentOpAbsent = SQL Agent Operator '{0}' is absent.
    SqlAgentOpAlertPresent = SQL Agent Alert '{0}' is present for operator '{1}'.
    SqlAgentOpAlertAbsent = SQL Agent Alert '{0}' is absent for operator '{1}'.
    ConnectServerFailed = Unable to connect to {0}\\{1}.
    UpdateNotificationType = Updating notification type for SQL Agent Operator '{0}' to '{1}'.
    UpdateOperatorAlertSetError = Unable to update the notification for alert '{0}' for the operator '{1}' on {2}\\{3}.


    AddSqlAgentOperator = Adding SQL Agent Operator '{0}'.
    CreateOperatorSetError = Unable to create the SQL Agent Operator '{0}' on {1}\\{2}.
    DeleteSqlAgentOperator = Deleting SQL Agent Operator '{0}'.
    DropOperatorSetError = Unable to drop the SQL Agent Operator '{0}' on {1}\\{2}.
    TestSqlAgentOperator = Checking if SQL Agent Operator '{0}' is present or absent.
    SqlAgentOperatorExistsButShouldNot = SQL Agent Operator exists but ensure is set to Absent. The SQL Agent Operator '{0}' should be deleted.
    SqlAgentOperatorDoesNotExistButShould  = SQL Agent Operator does not exist but Ensure is set to Present. The SQL Agent Operator '{0}' should be created.
    SqlAgentOperatorExistsButEmailWrong  = SQL Agent Operator '{0}' exists but has the wrong email address. Email address is currently '{1}' and should be updated to '{2}'.
'@
