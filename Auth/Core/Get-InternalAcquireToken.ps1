Function Get-InternalAcquireToken
{
    [CmdletBinding(DefaultParameterSetName='VisibleCredPrompt')]
    Param (
        [Parameter(Mandatory=$true,ParameterSetName='ConnectByCredObject')]
		[System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory=$False,ParameterSetName='ConnectByCredObject')]
        [Parameter(Mandatory=$true,ParameterSetName='VisibleCredPrompt')]
        [String]$RedirectUri,
        
        [Parameter(Mandatory=$True)]
        [String]$LoginUrl,

        [Parameter(Mandatory=$True)]
        [String]$ClientId,

        [Parameter(Mandatory=$True)]
        [String]$ResourceUrl,

        [ValidateSet("Never", "Auto", "Suppress", "Always")]
        [String]$PromptBehavior,
        
        [Parameter(Mandatory=$True,ParameterSetName='ConnectByRefreshToken')]
        $RefreshToken
    )
    

    $AuthContext = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList ($LoginUrl)
    

    if ($PSCmdlet.ParameterSetName -eq "ConnectByCredObject")
    {
        #$PromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Never
        
        Try
        {
            #TODO: check #GET https://login.microsoftonline.com/common/UserRealm/trond.hindenes@nordcloud.com?api-version=1.0 HTTP/1.1
            $Url = "https://login.microsoftonline.com/Common/oauth2/token"
            
            $encodedResource = [System.Net.WebUtility]::UrlEncode($resourceurl) 
            $body = "resource=$($encodedResource)&client_id=$($DefaultClientId)&grant_type=password&username=$($Credential.Username)&scope=openid&password=$($Credential.GetNetworkCredential().Password)"

            $Result = Invoke-RestMethod -UseBasicParsing -Method Post -Uri $Url -Body $body -ContentType "application/x-www-form-urlencoded"
            $AuthResult = "" | Select AccessToken, RefreshToken, ExpiresOn

            $Expires = [System.DateTimeOffset]::FromUnixTimeSeconds($Result.expires_on)
            $ExpiresUtc = $Expires.UtcDateTime
            
            $AuthResult.AccessToken = $Result.access_token
            $AuthResult.ExpiresOn = $ExpiresUtc
            $AuthResult.RefreshToken = $Result.refresh_token

            return $AuthResult
        }
        Catch
        {
        }
        
    }
    ElseIf($PSCmdlet.ParameterSetName -eq "VisibleCredPrompt")
    {
        if ($PromptBehavior -eq "Always")
        {
            $ThisPromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always
        }
        Elseif ($PromptBehavior -eq "Suppress")
        {
            $ThisPromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Never
        }
        Else
        {
            #Check the credential cache to see if we already have an entry we can use
            $CacheHit = $AuthContext.TokenCache.ReadItems() | where {$_.Authority -eq $LoginUrl}
            if ($CacheHit)
            {
                Write-verbose "     Attempting to authenticate using TokenCache"
                $ThisPromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Never
            }
            Else
            {
                $ThisPromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto
            }
            
        }
        Try
        {
            $AuthPlatformParameters = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList ($ThisPromptBehavior)
            $authResult = $AuthContext.AcquireTokenAsync($ResourceUrl,$ClientId, $RedirectUri, $AuthPlatformParameters)
            if ($authResult.Exception)
            {
                throw $authResult.Exception.ToString()
            }
            
            $authResult.Wait()
            $authresult = $authResult.result
        }
        Catch
        {
            if ($_.Exception.Message -match "User canceled authentication")
            {
                Write-error "User Canceled authentication"
                return
            }
            if (($PromptBehavior -eq "Suppress") -or ($PromptBehavior -eq "Auto"))
            {
                #If that failed, and suppress is on, switch to auto
                $ThisPromptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto
                $AuthPlatformParameters = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList ($ThisPromptBehavior)
                $authResult = $AuthContext.AcquireTokenAsync($ResourceUrl,$ClientId, $RedirectUri, $AuthPlatformParameters)
                $authResult.Wait()
                $authResult = $authResult.result
            }
        }
        
    }
    ElseIf($PSCmdlet.ParameterSetName -eq "ConnectByRefreshToken")
    {
        try
        {
            $Assertion = New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList ($RefreshToken)
            $authResult = $AuthContext.AcquireTokenAsync($Assertion,$ClientId)
            $authResult.Wait()
            $authresult = $authResult.result
        }
        Catch
        {
            Write-error "Error acquiring updated token using refresh token."
            return
        }
        
    }

    if ($authResult)
    {
        Return $authResult
    }

}

