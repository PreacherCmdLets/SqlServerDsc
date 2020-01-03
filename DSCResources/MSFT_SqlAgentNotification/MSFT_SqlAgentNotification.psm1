$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'

$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SqlServerDsc.Common'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SqlServerDsc.Common.psm1')

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SqlAgentNotification'

<#
    .SYNOPSIS
    This function gets the SQL Agent Notifications for a SQL Agent Alert for a SQL Agent Operator.

    .PARAMETER Operator
    The name of the SQL Agent Operator.

    .PARAMETER Alert
    The name of the SQL Agent Alert.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER NotificationType
    The type of SQL Agent Alert notification for the SQL Agent Operator.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Operator,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Alert,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $NotificationType

    )

    $returnValue = @{
        Operator          = $null
        Alert             = $null
        Ensure            = 'Absent'
        ServerName        = $ServerName
        InstanceName      = $InstanceName
        NotificationType  = $NotificationType
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetSqlOpAlerts
        )

        # Check alert exists
        $sqlAlertObject = $sqlServerObject.JobServer.Alerts | Where-Object {$_.Name -eq $Alert}
        if ($sqlAlertObject)
        {
            Write-Verbose -Message (
            $script:localizedData.SqlAgentOpAlertPresent `
                -f $Alert
            )
            $returnValue['Alert'] = $sqlAlertObject.Name
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentOpAlertAbsent `
                    -f $Alert, $Operator
            )
        }

        # Check operator exists
        $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Operator}
        if ($sqlOperatorObject)
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentOpPresent `
                    -f $Operator
            )
            $returnValue['Operator'] = $sqlOperatorObject.Name
            $sqlOperatorAlertObject = $sqlOperatorObject.EnumNotifications() | Where-Object {$_.AlertName -eq $Alert}

            if ($sqlOperatorAlertObject)
            {
                $returnValue['Ensure'] = 'Present'

                $notificationTypes = @()
                if ($sqlOperatorAlertObject.UseEmail)
                {
                    $notificationTypes += 'Email'
                }
                if ($sqlOperatorAlertObject.UsePager)
                {
                    $notificationTypes += 'Pager'
                }

                if ($notificationTypes)
                {
                    $returnValue['NotificationType'] = $notificationTypes
                }
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentOpAbsent `
                    -f $Operator
            )
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ConnectServerFailed -f $ServerName, $InstanceName
        New-InvalidOperationException -Message $errorMessage
    }

    return $returnValue
}

<#
    .SYNOPSIS
    This function sets the SQL Agent Operator.

    .PARAMETER Ensure
    Specifies if the SQL Agent Operator Alert notification should be present or absent. Default is Present

    .PARAMETER Operator
    The name of the SQL Agent Operator.

    .PARAMETER Alert
    The name of the SQL Agent Alert.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER NotificationType
    The type of SQL Agent Alert notification for the SQL Agent Operator.
#>
    function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Operator,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Alert,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $NotificationType
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Operator}
        $sqlAgentAlertObject = $sqlServerObject.JobServer.Alerts | Where-Object {$_.Name -eq $Alert}
        if ($sqlOperatorObject -and $sqlAgentAlertObject)
        {
            switch ($Ensure)
            {
                'Present'
                {
                    try
                    {
                        $NotifyMethod = 0
                        if ($NotificationType -contains 'Email')
                        {
                            $NotifyMethod += 1
                        }
                        if ($NotificationType -contains 'Pager')
                        {
                            $NotifyMethod += 2
                        }

                        $sqlAgentOpAlerts = $sqlOperatorObject.EnumNotifications() | Where-Object {$_.AlertName -eq $Alert}
                        if ($sqlAgentOpAlerts)
                        {
                            # check type and update if needed
                            $NotifyCheck = 0
                            if ($sqlAgentOpAlerts.HasEmail)
                            {
                                $NotifyCheck += 1
                            }
                            if ($sqlAgentOpAlerts.HasPager)
                            {
                                $NotifyCheck += 2
                            }
                            if ($NotifyMethod -ne $NotifyCheck)
                            {
                                Write-Verbose -Message (
                                $script:localizedData.UpdateNotificationType `
                                    -f $Operator, ($NotificationType -join ', ')
                                )

                                $SqlOperatorObject.UpdateNotification($sqlAgentAlertObject.Name, $NotifyMethod)
                            }
                        }
                        else
                        {
                            Write-Verbose -Message (
                            $script:localizedData.AddNotificationType `
                                -f $Operator, ($NotificationType -join ', ')
                            )

                            $SqlOperatorObject.AddNotification($sqlAgentAlertObject.Name, $NotifyMethod)
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.UpdateOperatorAlertSetError -f $Alert, $Operator, $ServerName, $InstanceName
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
                'Absent'
                {
                    try
                    {
                        $sqlAgentOpAlerts = $sqlOperatorObject.EnumNotifications() | Where-Object {$_.AlertName -eq $Alert}
                        if ($sqlAgentOpAlerts)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.RemoveOpAlertNotification `
                                    -f $Operator, $Alert, $ServerName, $InstanceName
                            )
                            $SqlOperatorObject.RemoveNotification($sqlAgentAlertObject.Name)
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.RemoveOpAlertError -f $Name, $ServerName, $InstanceName
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }
        }
        else
        {
            try
            {
                if (!$sqlOperatorObject)
                {
                    $errorMessage = $script:localizedData.OperatorDoesNotExist -f $Operator, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
                if (!$sqlAgentAlertObject)
                {
                    $errorMessage = $script:localizedData.AlertDoesNotExist -f $Alert, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
            }
            catch
                {
                    $errorMessage = $script:localizedData.CheckExistenceError -f $Alert, $Operator, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ConnectServerFailed -f $ServerName, $InstanceName
        New-InvalidOperationException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
    This function tests the SQL Agent Operator.

    .PARAMETER Ensure
    Specifies if the SQL Agent Operator Alert notification should be present or absent. Default is Present

    .PARAMETER Operator
    The name of the SQL Agent Operator.

    .PARAMETER Alert
    The name of the SQL Agent Alert.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER NotificationType
    The type of SQL Agent Alert notification for the SQL Agent Operator.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Operator,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Alert,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String[]]
        $NotificationType
    )

    Write-Verbose -Message (
        $script:localizedData.TestSqlAgentOpAlert `
            -f $Alert, $Operator
    )

    $getTargetResourceParameters = @{
        Operator       = $Operator
        Alert          = $Alert
        ServerName     = $ServerName
        InstanceName   = $InstanceName
    }

    $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
    $isOperatorInDesiredState = $true

    switch ($Ensure)
    {
        'Absent'
        {
            if ($getTargetResourceResult.Ensure -ne 'Absent')
            {
                Write-Verbose -Message (
                    $script:localizedData.SqlAgentOpAlertExistsButShouldNot `
                        -f ($NotificationType -join ', ')
                )
                $isOperatorInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.Operator -and $getTargetResourceResult.Alert)
            {
                if ($getTargetResourceResult.NotificationType)
                {
                    if ((Compare-Object -ReferenceObject $getTargetResourceResult.NotificationType -DifferenceObject $NotificationType))
                    {
                        Write-Verbose -Message (
                            $script:localizedData.SqlAgentOpAlertExistsButNotificationWrong `
                                -f ($getTargetResourceResult.NotificationType -join ','), ($NotificationType -join ', ')
                        )
                        $isOperatorInDesiredState = $false
                    }
                    elseif ($getTargetResourceResult.Ensure -ne 'Present')
                    {
                        Write-Verbose -Message (
                            $script:localizedData.SqlAgentOpAlertDoesNotExistButShould `
                                -f $Operator, $Alert
                        )
                        $isOperatorInDesiredState = $false
                    }
                }
                else {
                    Write-Verbose -Message (
                        $script:localizedData.SqlAgentOpAlertExistsButNotificationWrong `
                            -f ($getTargetResourceResult.NotificationType -join ','), ($NotificationType -join ', ')
                    )
                    $isOperatorInDesiredState = $false
                }
            }
            else
            {
                $MissingObject = @()
                if(!$getTargetResourceResult.Operator)
                {
                    $MissingObject += "Operator ($Operator)"
                }
                if(!$getTargetResourceResult.Alert)
                {
                    $MissingObject += "Alert ($Alert)"
                }
                $errorMessage = $script:localizedData.MissingObject -f ($MissingObject -join ', '), $ServerName, $InstanceName
                New-InvalidOperationException -Message $errorMessage
            }
        }
    }
    $isOperatorInDesiredState
}

function Test-NotificationType
{
    param (
        [Parameter()]
        $sqlOperatorAlertObject,

        [Parameter()]
        [System.String[]]
        $NotificationType
        )

        $returnValue = @{
            Ensure            = 'Absent'
            CurrentNotificationType  = $null
            DesiredNotificationType  = $NotificationType
        }

        $NotifyMethod = 0
        if ($NotificationType -contains 'Email')
        {
            $NotifyMethod += 1
        }
        if ($NotificationType -contains 'Pager')
        {
            $NotifyMethod += 2
        }

        if ($sqlOperatorAlertObject)
        {
            # check type and update if needed
            $NotifyCheck = 0
            if ($sqlOperatorAlertObject.HasEmail)
            {
                $NotifyCheck += 1
            }
            if ($sqlOperatorAlertObject.HasPager)
            {
                $NotifyCheck += 2
            }
            if ($NotifyMethod -ne $NotifyCheck)
            {
                return $false
            }


        return $sqlOperatorAlertObject

}

Export-ModuleMember -Function *-TargetResource
Export-ModuleMember -Function Test-NotificationType
