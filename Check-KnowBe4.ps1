<#
.SYNOPSIS
Checks parent domain of a url for the KnowBe4 DNS TXT record

.DESCRIPTION
Checks parent domain of a url for the KnowBe4 DNS TXT record

.PARAMETER Url
Website link to review.

.EXAMPLE
Check-KnowBe4.ps1 -Url https://breakingnews.comano.us/blah/blah.php

.AUTHOR
keyboardcrunch
#>

param (
    [string]$Url = $(throw "-Url is required.")
)

Try {
    $Url = ([System.URI]$Url).host
} Catch {
    Write-Error "Error parsing the Url!"
}

$fqdn = $Url.Substring((($Url.Substring(0,$Url.LastIndexOf("."))).LastIndexOf(".")+1),$Url.Length-(($Url.Substring(0,$Url.LastIndexOf("."))).LastIndexOf(".")+1))
$txt = Resolve-DnsName -Name $fqdn -Type txt

If ($txt.Strings -contains "v=spf1 include:_phishspf.knowbe4.com ~all") {
    Write-Host "Likely KnowBe4 Domain" -ForegroundColor Green
    Return $txt.Strings
} Else {
    Write-Host "Not likely KnowBe4!" -ForegroundColor Red
    Return $txt.Strings
}
