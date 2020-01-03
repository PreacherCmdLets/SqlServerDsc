# Localized resources for MSFT_SqlServerAgentNotification

ConvertFrom-StringData @'
    GetSqlOpAlerts = Getting SQL Agent Operator's Alerts.
    SqlAgentOpPresent = SQL Agent Operator '{0}' is present.
    SqlAgentOpAbsent = SQL Agent Operator '{0}' is absent.
    SqlAgentOpAlertPresent = SQL Agent Alert '{0}' is present.
    SqlAgentOpAlertAbsent = SQL Agent Alert '{0}' is absent for operator '{1}'.
    ConnectServerFailed = Unable to connect to {0}\\{1}.
    UpdateNotificationType = Updating notification type for SQL Agent Operator '{0}' to '{1}'.
    AddNotificationType = Add notification type for SQL Agent Operator '{0}' to '{1}'.
    UpdateOperatorAlertSetError = Unable to update the notification for alert '{0}' for the operator '{1}' on {2}\\{3}.
    OperatorDoesNotExist = SQL Agent Operator '{0}' does not exist on {1}\\{2}.
    AlertDoesNotExist = SQL Agent Alert '{0}' does not exist on {1}\\{2}.
    CheckExistenceError = Unable to check both operator '{0}' and alert '{1}' exist on {2}\\{3}.
    RemoveOpAlertNotification = Removing notification for operator '{0}' for alert '{1}' on {2}\\{3}.
    RemoveOpAlertError = Unable to remove notification for operator '{0}' for alert '{1}' on {2}\\{3}.
    TestSqlAgentOpAlert = Checking if the notification for the '{0}' Alert for SQL Agent Operator '{1}' is present or absent.
    SqlAgentOpAlertExistsButShouldNot = SQL Alert notification for SQL Agent Operator exists but ensure is set to Absent. The notification '{0}' should be removed.
    SqlAgentOpAlertExistsButNotificationWrong = SQL Alert notification for SQL Agent Operator exists but has the wrong notification. Notification is currently '{0}' and should be updated to '{1}'.
    SqlAgentOpAlertDoesNotExistButShould = SQL Alert notification for SQL Agent Operator does not exist but Ensure is set to Present. The SQL Agent Operator '{0}' should have notifications created for '{1}' alert.
    MissingObject = The following object(s) must exist before configuring the notification. '{0}' missing from {1}\\{2}.
'@
