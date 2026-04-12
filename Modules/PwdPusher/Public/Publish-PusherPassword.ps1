function Publish-PusherPassword {
    <#
    .SYNOPSIS
        Pushes the password to public pwpush.com or a private instance of Password Pusher and retrieves the link.
    .DESCRIPTION
        Publishes a SecureString password to a Password Pusher service and returns a shareable URL.
        The URL will expire after the specified number of days or views.
        Uses HTTPS by default for secure transmission.
    .PARAMETER Password
        Password to push. Should be specified as SecureString.
        Plain-text passwords will be converted with a warning (aliased as -p).
    .PARAMETER Days
        Number of days before the link expires. Default is 7 days. Valid range: 1-90 days (aliased as -d).
    .PARAMETER Views
        Number of views before the link expires. Default is 7 views. Valid range: 1-100 views (aliased as -v).
    .PARAMETER Server
        Specifies server/service to use. Default is "pwpush.com".
        Use FQDN format with optional port (e.g., "localhost:5100") (aliased as -s).
    .PARAMETER KillSwitch
        Allows anyone accessing the link to delete it before it expires (aliased as -k).
    .PARAMETER FirstView
        Use the "First view" experience that's not counted towards maximum views.
        Due to a bug in some pwpush versions, this may not work as expected (aliased as -f).
    .PARAMETER Wipe
        Dispose the SecureString password from memory after successful publishing (aliased as -w).
    .PARAMETER UseHttp
        Use HTTP instead of HTTPS. Only use for local development/testing.
    .EXAMPLE
        $SecurePass | Publish-PusherPassword
        Pushes password to default pwpush.com service with HTTPS
    .EXAMPLE
        Publish-PusherPassword -Password $SecurePass -Server "localhost:5100" -UseHttp
        Pushes to local instance using HTTP
    .EXAMPLE
        Publish-PusherPassword -Password $SecurePass -Days 3 -Views 10 -KillSwitch
        Pushes password expiring after 3 days or 10 views with delete capability
    .OUTPUTS
        System.String - The URL to share for password retrieval
    #>

    [CmdletBinding()]
    [Alias("pppwd")]
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)][Alias("p")][Security.SecureString]$Password,
        [Alias("d")][ValidateRange(1,90)][int]$Days=7,
        [Alias("v")][ValidateRange(1,100)][int]$Views=7,
        [Alias("s")][ValidateNotNullOrEmpty()][string]$Server = "pwpush.com",
        [Alias("k")][switch]$KillSwitch,
        [Alias("f")][switch]$FirstView,
        [Alias("w")][switch]$Wipe,
        [switch]$UseHttp
    )

    # Determine protocol (default to HTTPS for security)
    $Protocol = if ($UseHttp) { "http" } else { "https" }

    # Build base URL
    $BaseUrl = "${Protocol}://$Server"

    Write-Verbose "Using server: $BaseUrl"
    Write-Verbose "Expires after: $Days days or $Views views"

    # If the password is supplied as anything but SecureString, throw a warning and force-convert it
    if ($Password -isnot [securestring]) {
        Write-Host -ForegroundColor Yellow "You should use SecureString type to process passwords in scripts. Converting now..."
        [securestring]$Password = ConvertTo-SecureString ([string]$Password) -AsPlainText -Force
    }

    # Push the password, retrieve the response. Building the body on-the-fly to keep unsecured password not stored in a variable
    try {
        $Reply = Invoke-RestMethod -Method 'Post' -Uri "$BaseUrl/p.json" -ContentType "application/json" -ErrorAction Stop -Body ([pscustomobject]@{
        password = if ($KillSwitch) {[pscustomobject]@{
                payload = ConvertFrom-SecurePassword $Password
                expire_after_days = $Days
                expire_after_views = $Views
                deletable_by_viewer = $KillSwitch.IsPresent.ToString().ToLower()
                first_view = $FirstView.IsPresent.ToString().ToLower()
           }
        } else {
            [pscustomobject]@{
                payload = ConvertFrom-SecurePassword $Password
                expire_after_days = $Days
                expire_after_views = $Views
                first_view = $FirstView.IsPresent.ToString().ToLower()
            }
        }
        } | ConvertTo-Json)

        if ($Reply.url_token) {
            if ($Reply.first_view -gt $FirstView.IsPresent) {
                Invoke-RestMethod -Method 'Get' -Uri "$BaseUrl/p/$($Reply.url_token).json" -ErrorAction SilentlyContinue | Out-Null
                Write-Warning "The version of PasswordPusher you're using is outdated and doesn't properly support FirstView switch. Please update to a build that includes pull request #112"
            }

            # Dispose of secure password object - note it's the original object, not a function-local copy
            if ($Wipe) {
                $Password.Dispose()
                Write-Verbose "SecureString password has been disposed from memory"
            }

            $ResultUrl = "$BaseUrl/en/p/$($Reply.url_token)"
            Write-Verbose "Password successfully pushed to: $ResultUrl"
            return $ResultUrl

        } else {
            Write-Error "Unable to get URL token from service response"
        }
    }
    catch {
        Write-Error "Failed to publish password to $BaseUrl : $_"
        if ($_.Exception.Response.StatusCode) {
            Write-Error "HTTP Status Code: $($_.Exception.Response.StatusCode.value__)"
        }
        throw
    }
} #End function