$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFolderHere = (Get-Item $Here).FullName.Replace("\Tests","")
$here = $ModuleFolderHere
$ModuleFolder = Split-Path $moduleFolderHere -Parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
Import-Module "$ModuleFolder\blue.psd1" -force

$FailingCred = New-Object System.Management.Automation.PsCredential("nope", ("nope" | convertTo-SecureString -asplainText -Force))

Describe "Connect-ArmSubscription" {
#    It "Accepts a credential parameter" {
#        Connect-ArmSubscription -Credential $FailingCred | Should Not Throw
#   }
    
#    It "Doesn't output anything on fail" {
#        Connect-ArmSubscription -Credential $FailingCred | Should be $null
#    }

    It "Output subscription on success" {
        (Connect-ArmSubscription).SubscriptionId | Should not be $null
    }
    
    It "Have a guid-parseable output on success" {
        {[System.Guid]::Parse((Connect-ArmSubscription).SubscriptionId)} | Should not throw
    }

    It "Not throw on failure" {
        {Connect-ArmSubscription -credential $FailingCred -ErrorAction SilentlyContinue -ErrorVariable myErr} | Should not throw
    }

    It "Produce the right error message on failure" {
            Connect-ArmSubscription -credential $FailingCred -ErrorAction SilentlyContinue -ErrorVariable myErr
            $myerr[0].Exception.Message | Should be "Error Authenticating"
    }


}