$Script:thismodulepath = $psscriptroot

if ($PSVersionTable.PSEdition -eq $null)
{
    $PSEdition = "Desktop"
}

write-verbose "PsEdition is $Psedition, loading dlls from $($psscriptroot)\bin\$($PsEdition)\"

foreach ($File in Get-Childitem "$($psscriptroot)\bin\$($PsEdition)\")
{
    write-verbose "Loading file $($file.fullname)"
    Import-Module $file.fullname
}

Function Load-InternalFunctionFile
{
    Param ($FunctionPath)
    $FileList = @()
    Write-Verbose "Loading functions from $FunctionPath"
    $FileList += Get-ChildItem $FunctionPath\*.ps1
    $FileList += get-childitem (Join-Path $FunctionPath $PSEdition)  -ErrorAction SilentlyContinue| where {$_.Extension -eq ".ps1"} -ErrorAction SilentlyContinue
    if (get-childitem (Join-Path $FunctionPath $PSEdition) -ErrorAction SilentlyContinue)
    {
        Write-Verbose "Platform-specific path found, loading functions from $(Join-Path $FunctionPath $PSEdition)"
    }
    $FileList = $FileList | where {$_.Extension -match "ps"}
    $FileList
}

#Load function files
$Load = @()
$Load += Load-InternalFunctionFile $psscriptroot\Auth
$Load += Load-InternalFunctionFile $psscriptroot\Rest
$Load += Load-InternalFunctionFile $psscriptroot\ResourceGroup
$Load += Load-InternalFunctionFile $psscriptroot\Resource
$Load += Load-InternalFunctionFile $psscriptroot\VirtualMachine
$Load += Load-InternalFunctionFile $psscriptroot\Network
$Load += Load-InternalFunctionFile $psscriptroot\Automation
$Load += Load-InternalFunctionFile $psscriptroot\Helpers
$Load += Load-InternalFunctionFile $psscriptroot\TemplateDeployment
foreach ($File in $Load){. $file.FullName}

#Setup internal variables. These will be filled by Connect-ArmSubscription and should not be manipulated directly other functions.
[string]$script:CurrentSubscriptionId = $null
[string]$script:AuthToken = $null
[string]$script:RefreshToken = $null
[Nullable[System.DateTimeOffset]]$script:TokenExpirationUtc = $null
$Script:AllSubscriptions = @()

#Pre-Canned variables
$Script:LoginUrl = "https://login.microsoftonline.com/common/oauth2/authorize"
$Script:ResourceUrl = "https://management.core.windows.net/"
$Script:DefaultAuthRedirectUri = "urn:ietf:wg:oauth:2.0:oob"
$Script:DefaultClientId = "1950a258-227b-4e31-a9cf-717495945fc2"
$Script:AzureServiceLocations = @()
$Script:ImageSearchApiUrl = "http://blueimageapiweb.azurewebsites.net/api"

#Other Defaults - verboseing web/rest requests is too noisy
$Script:PsDefaultParameterValues.Add("Invoke-RestMethod:Verbose",$False)
$Script:PsDefaultParameterValues.Add("Invoke-WebRequest:Verbose",$False)

#Load autoload classes. Every file in Classes\Autoload needs to be a valid .cs file
if ($PSEdition -eq "Desktop")
{
    $Files = Get-ChildItem (Join-path $Script:thismodulepath "Classes\AutoLoad")
    Write-verbose "Loading types in folder Classes\AutoLoad"
    try
    {
        foreach ($file in $files | where {$_.Extension -eq ".cs"})
        {
            Write-verbose "Loading type file $($File.FullName)"
            add-Type -Path ($File.FullName)
        }
    }
    catch
    {
        foreach ($file in $files |where {$_.Extension -eq ".cs"})
        {
            Write-verbose "Loading type file $($File.FullName) (2nd try)"
            add-Type -Path ($File.FullName)
        }
    }

}


<#
foreach ($file in $files)
{
    
}
#>

#Load tab completers
<#
if (get-module TabExpansionPlusPlus -list -ErrorAction 0)
{
    Write-verbose "Module TabExpansionPlusPlus found, loading argument completer scripts"
    $CompleterScriptList = Get-ChildItem -Path $PSScriptRoot\Completers\*.ps1
    foreach ($CompleterScript in $CompleterScriptList) {
        Write-Verbose -Message ('Import argument completer script: {0}' -f $CompleterScript.FullName)
        . $CompleterScript.FullName
    }
    Write-Verbose -Message 'Finished importing argument completer scripts.'    
}
#>

