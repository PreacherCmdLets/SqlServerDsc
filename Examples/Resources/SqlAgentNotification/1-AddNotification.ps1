<#
    .EXAMPLE
        This example shows how to ensure that the SQL Agent Operator
        DbaTeam has email notifications set up for the 825 Error Alert.
#>

Configuration Example
{

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlAgentNotification Add_DbaTeam_Notification {
            Ensure               = 'Present'
            Operator             = 'DbaTeam'
            Alert                = '825 Error'
            ServerName           = 'TestServer'
            InstanceName         = 'MSSQLServer'
            NotificationType     = 'email'
        }
    }
}
