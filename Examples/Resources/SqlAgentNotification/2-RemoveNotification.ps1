<#
    .EXAMPLE
        This example shows how to ensure that the SQL Agent Operator
        DbaTeam doesn't have notifications set up for the 825 Error Alert.
#>

Configuration Example
{

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlAgentNotification Remove_DbaTeam_Notification {
            Ensure               = 'Absent'
            Operator             = 'DbaTeam'
            Alert                = '825 Error'
            ServerName           = 'TestServer'
            InstanceName         = 'MSSQLServer'
        }
    }
}
