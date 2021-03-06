$ThisFolder = get-location | select -ExpandProperty path
$TestsFolder = join-path $ThisFolder "Tests"
Import-Module "$ThisFolder\blue.psd1"
#Import-Module "$ModuleFolder\blue.psm1" -force

if (Get-item "$ThisFolder\LocalVars.Config" -ErrorAction SilentlyContinue)
{
    . "$TestsFolder\ConfigureTestEnvironment.ps1" -FilePath "$ThisFolder\LocalVars.config"
}

$FailingCred = New-Object System.Management.Automation.PsCredential("nope", ("nope" | convertTo-SecureString -asplainText -Force))
$SuceedingCred = New-Object System.Management.Automation.PsCredential($env:logonaccountusername, ($env:logonaccountuserpassword | convertTo-SecureString -asplainText -Force))
$WorkingSubscriptionId = $env:SubscriptionId


Function ParseGuid
{
    Param ($Guid)
    Try
    {
        $Guid = [System.Guid]::Parse($Guid)
    }
    Catch
    {
        return $null
    }
    
    return $Guid.Tostring()
}


#Tests tagged with "interactive"" cannot be run by CI
Describe -Tag "Interactive" "Connect-ArmSubscription" {
    It "Output subscription on success" {
        (Connect-ArmSubscription -ForceShowUi).SubscriptionId | Should not be $null
    }
    
    It "Have a guid-parseable output on success" {
        {[System.Guid]::Parse((Connect-ArmSubscription -ForceShowUi).SubscriptionId)} | Should not throw
    }
}

if ($PSVersionTable.PSVersion.Major -eq 4)
{
    Describe "Connect-ArmSubscription" {
        It "Produce the right error message on failure (v4)" {
            Connect-ArmSubscription -credential $FailingCred -ErrorAction SilentlyContinue -ErrorVariable myErr
            $myerr[0].Exception.Message | Should be "Error Authenticating"
        }
    }

}

if ($PSVersionTable.PSVersion.Major -eq 5)
{
    Describe "Connect-ArmSubscription" {
        It "Produce the right error message on failure (v5)" {
            Connect-ArmSubscription -credential $FailingCred -ErrorAction SilentlyContinue -ErrorVariable myErr
            $myerr[1].Exception.Message | Should be "Error Authenticating"
        }
    }

}

Describe "Connect-ArmSubscription" {
    It "Not throw on failure" {
        {Connect-ArmSubscription -credential $FailingCred -ErrorAction SilentlyContinue -ErrorVariable myErr} | Should not throw
    }

    It "is able to log on to Azure without specifying subscriptionid" {
        (Connect-ArmSubscription -credential $SuceedingCred).SubscriptionId | Should Not BeNullOrEmpty
    }
    
    It "is able to log on to Azure" {
        (Connect-ArmSubscription -credential $SuceedingCred -SubscriptionId $WorkingSubscriptionId).SubscriptionId | Should Not BeNullOrEmpty
    }
    

    It "Has a guid-parseable output on success when subscriptionId is specified" {
        $Guid = (Connect-ArmSubscription -credential $SuceedingCred -SubscriptionId $env:subscriptionid).SubscriptionId
        $Result = ParseGuid -Guid $guid
        $Result | Should be $env:subscriptionid
    }
    
    It "Has a guid-parseable output on success when tenantid is specified" {
        $Guid = (Connect-ArmSubscription -credential $SuceedingCred -TenantId $env:tenantid -SubscriptionId $WorkingSubscriptionId).SubscriptionId
        $Result = ParseGuid -Guid $guid
        $Result | Should be $env:subscriptionid
    }
    
    It "Fails correctly when the user is not connected to the specified tenant" {

            Connect-ArmSubscription -credential $SuceedingCred -TenantId "somethingSomething" -ErrorAction SilentlyContinue -ErrorVariable myErr
            $myerr[0].Exception.Message | Should Match "The logged on user is not connected to tenant"
    }
    
    It "Has a guid-parseable output on success when both tenantid and subscriptionid is specified" {
        $Guid = (Connect-ArmSubscription -credential $SuceedingCred -TenantId $env:tenantid -SubscriptionId $env:subscriptionid).SubscriptionId
        $Result = ParseGuid -Guid $guid
        $Result | Should be $env:subscriptionid
    }

<#
    It "Has a guid-parseable output on success when subscriptionId is not specified" {
        $Guid = (Connect-ArmSubscription -credential $SuceedingCred).SubscriptionId
        $Result = ParseGuid -Guid $guid
        $Result | Should be $env:subscriptionid
    }
#>
}
 
Describe "ConfigFile" {
    $Json = Get-Content "Config\apiversions.json" -Raw | convertfrom-Json
    
    It "should be parseable json" {
         $Json |  Should Not BeNullOrEmpty
    }
}
