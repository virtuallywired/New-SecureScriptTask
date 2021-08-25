Function New-SecureScriptTask {
    <#
.SYNOPSIS
This function registers a PowerShell script task in Windows Task Scheduler with added script security.

.DESCRIPTION
This function registers a PowerShell script task in Windows Task Scheduler with added script security by checking the file matches the original file.

.PARAMETER ScriptPath
Specify the full path of the PowerShell script file.

.PARAMETER TaskName
Specifies the name of a scheduled task.

.PARAMETER TaskDescription
Briefly describes the task. If not specified the TaskName will be used.

.PARAMETER UserID
Specifies the user ID that Task Scheduler uses to run the tasks that are associated with the principal.

.PARAMETER RunLevel
Specifies the level of user rights that Task Scheduler uses to run the tasks that are associated with the principal.

.EXAMPLE
New-SecureScriptTask -ScriptPath "C:\Scripts\Delete-User.ps1" -TaskName "Delete-User-Task"

.EXAMPLE
$Params = @{
    ScriptPath      = "C:\Scripts\Delete-User.ps1";
    TaskName        = "Delete-User-Task";
    TaskDescription = "Delete User Task";
    UserId          = "Administrator";
    RunLevel        = "Highest"
}
New-SecureScriptTask @Params

.NOTES
Developed by Nicholas Mangraviti

.LINK
https://virtuallywired.io

#>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $ScriptPath })]
        [String]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [String]$TaskName,
        [Parameter(Mandatory = $false)]
        [String]$TaskDescription = $TaskName,
        [Parameter(Mandatory = $false)]
        [String]$UserID = "Administrator",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Highest", "Limited")]
        [String]$RunLevel = "Highest"
    )
    ## Creating Task Argument String Using File Hash and Script Path.
    [string]$TaskArg = 'If ((Get-FileHash "{0}").Hash -eq "{1}") {{"{0}"}}' -f $ScriptPath, (Get-FileHash -Path $ScriptPath).Hash
    
    ## Creating New Task Action.
    $Params = @{
        Execute  = "powershell.exe";
        Argument = "$($TaskArg)"
    }
    $TaskAction = New-ScheduledTaskAction @Params
    
    ## Creating Task Principal.
    $Params = @{
        UserId   = "$($UserID)";
        RunLevel = "$($RunLevel)"
    }
    $TaskPrincipal = New-ScheduledTaskPrincipal @Params
    
    # Registering The Scheduled Task.
    $Params = @{
        TaskName    = $TaskName;
        Action      = $TaskAction;
        Description = $TaskDescription;
        Principal   = $TaskPrincipal
    }
    Register-ScheduledTask @Params
}
