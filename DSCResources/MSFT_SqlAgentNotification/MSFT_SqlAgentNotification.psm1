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
        $InstanceName

    )

    $returnValue = @{
        Operator          = $null
        Alert             = $null
        Ensure            = 'Absent'
        ServerName        = $ServerName
        InstanceName      = $InstanceName
        NotificationType  = $null
    }

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        Write-Verbose -Message (
            $script:localizedData.GetSqlOpAlerts
        )

        # Check operator exists
        $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Operator}
        if ($sqlOperatorObject)
        {
            Write-Verbose -Message (
                $script:localizedData.SqlAgentOpPresent `
                    -f $Operator
            )

            # Check alert exists
            $sqlOperatorAlertObject = $sqlOperatorObject.EnumNotifications() | Where-Object {$_.AlertName -eq $Alert}
            if ($sqlOperatorAlertObject)
            {
                Write-Verbose -Message (
                $script:localizedData.SqlAgentOpAlertPresent `
                    -f $Alert, $Operator
                )

                $returnValue['Ensure'] = 'Present'
                $returnValue['Operator'] = $sqlOperatorObject.Name
                $returnValue['Alert'] = $sqlAgentAlert.Name

                $notificationTypes = @()
                if ($sqlOperatorAlertObject.UseEmail)
                {
                    $notificationTypes += 'Email'
                }
                if ($sqlOperatorAlertObject.UsePager)
                {
                    $notificationTypes += 'Pager'
                }
                $returnValue['NotificationType'] = $notificationTypes
            }
            else
            {
                Write-Verbose -Message (
                    $script:localizedData.SqlAgentOpAlertAbsent `
                        -f $Alert
                )
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
    Specifies if the SQL Agent Operator should be present or absent. Default is Present

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

        [Parameter()]
        [System.String]
        $NotificationType
    )

    $sqlServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName

    if ($sqlServerObject)
    {
        switch ($Ensure)
        {
            'Present'
            {
                $sqlOperatorObject = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Operator}
                $sqlAgentAlertObject = $sqlServerObject.JobServer.Alerts | Where-Object {$_.Name -eq $Alert}
                if ($sqlOperatorObject -and $sqlAgentAlertObject)
                {
                    if ($PSBoundParameters.ContainsKey('NotificationType'))
                    {
                        try
                        {
                            Write-Verbose -Message (
                                $script:localizedData.UpdateNotificationType `
                                    -f $Operator, ($NotificationType -join ', ')
                            )

                            $NotifyMethod = 0
                            if ($NotificationType -contains 'Email')
                            {
                                $NotifyMethod += 1
                            }
                            if ($NotificationType -contains 'Pager')
                            {
                                $NotifyMethod += 3
                            }

                            $sqlAgentOpAlerts = $sqlOperatorObject.EnumNotifications() | Where-Object {$_.AlertName -eq $Alert}
                            if ($sqlAgentOpAlerts)
                            {
                                # check type and update if needed

                            }
                            else
                            {
                                # no current alert so just update
                                $SqlOperatorObject.AddNotification($sqlAgentAlertObject.Name, $NotifyMethod)
                            }
                        }
                        catch
                        {
                            $errorMessage = $script:localizedData.UpdateOperatorAlertSetError -f $Alert, $Operator, $ServerName, $InstanceName
                            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                        }
                    }
                }
                else
                {
                    try
                    {
                        $sqlOperatorObjectToCreate = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.Operator -ArgumentList $sqlServerObject.JobServer, $Name

                        if ($sqlOperatorObjectToCreate)
                        {
                            Write-Verbose -Message (
                                $script:localizedData.AddSqlAgentOperator `
                                    -f $Name
                            )
                            if ($PSBoundParameters.ContainsKey('EmailAddress'))
                            {
                                Write-Verbose -Message (
                                    $script:localizedData.UpdateEmailAddress `
                                        -f $EmailAddress, $Name
                                )
                                $sqlOperatorObjectToCreate.EmailAddress = $EmailAddress
                            }
                            $sqlOperatorObjectToCreate.Create()
                        }
                    }
                    catch
                    {
                        $errorMessage = $script:localizedData.CreateOperatorSetError -f $Name, $ServerName, $InstanceName
                        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                    }
                }
            }

            'Absent'
            {
                try
                {
                    $sqlOperatorObjectToDrop = $sqlServerObject.JobServer.Operators | Where-Object {$_.Name -eq $Name}
                    if ($sqlOperatorObjectToDrop)
                    {
                        Write-Verbose -Message (
                            $script:localizedData.DeleteSqlAgentOperator `
                                -f $Name
                        )
                        $sqlOperatorObjectToDrop.Drop()
                    }
                }
                catch
                {
                    $errorMessage = $script:localizedData.DropOperatorSetError -f $Name, $ServerName, $InstanceName
                    New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
                }
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
    Specifies if the SQL Agent Operator should be present or absent. Default is Present

    .PARAMETER Name
    The name of the SQL Agent Operator.

    .PARAMETER ServerName
    The host name of the SQL Server to be configured. Default is $env:COMPUTERNAME.

    .PARAMETER InstanceName
    The name of the SQL instance to be configured.

    .PARAMETER EmailAddress
    The email address to be used for the SQL Agent Operator.
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
        $Name,

        [Parameter()]
        [System.String]
        $ServerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $EmailAddress
    )

    Write-Verbose -Message (
        $script:localizedData.TestSqlAgentOperator `
            -f $Name
    )

    $getTargetResourceParameters = @{
        Name           = $Name
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
                    $script:localizedData.SqlAgentOperatorExistsButShouldNot `
                        -f $Name
                )
                $isOperatorInDesiredState = $false
            }
        }

        'Present'
        {
            if ($getTargetResourceResult.EmailAddress -ne $EmailAddress -and $PSBoundParameters.ContainsKey('EmailAddress'))
            {
                Write-Verbose -Message (
                    $script:localizedData.SqlAgentOperatorExistsButEmailWrong `
                        -f $Name, $getTargetResourceResult.EmailAddress, $EmailAddress
                )
                $isOperatorInDesiredState = $false
            }
            elseif ($getTargetResourceResult.Ensure -ne 'Present')
            {
                Write-Verbose -Message (
                    $script:localizedData.SqlAgentOperatorDoesNotExistButShould `
                        -f $Name
                )
                $isOperatorInDesiredState = $false
            }
        }
    }
    $isOperatorInDesiredState
}

Export-ModuleMember -Function *-TargetResource
