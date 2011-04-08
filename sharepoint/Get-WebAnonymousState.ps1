param([string]$url = $(throw "url is required"))

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

$site = new-Object Microsoft.SharePoint.SPSite($url)
$web = $site.RootWeb

$anonProps = @{
  "Site.IISAllowsAnonymous" = $site.IISAllowsAnonymous
  "RootWeb.AllowAnonymousAccess" = $web.AllowAnonymousAccess
  "RootWeb.AnonymousState" = $web.AnonymousState
  "RootWeb.AnonymousPermMask64" = $web.AnonymousPermMask64
}

$web.Dispose()
$site.Dispose()

$anonProps