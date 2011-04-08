# Approve a list item in SharePoint using the web service apis

$documentUrl = "<document url>"
$listName = "Pages"

# serviceUrl - url of the Lists web service to connect to
# fileRef - a file ref pattern, e.g. pages/default.aspx or default.aspx
function Get-FileListItem($serviceUrl, $listName, $fileRef) {

  $query = @"
    <Query>
      <Where>
        <Contains>
          <FieldRef Name="FileRef"></FieldRef>
          <Value Type="Text">{0}</Value>
        </Contains>
      </Where>
    </Query>
"@

  $ls = new-spservice stspub.Services.Lists $serviceUrl
  $itemResults = $ls.GetListItems($listName, "", [xml]($query -f $fileRef), $null, 1, $null, $null)
  if(0 -eq $itemResults.data.ItemCount) {
    throw "Unable to find list item at url: $documentUrl"
  }

  return $itemResults.data.row
}
function Approve-ListItem($serviceUrl, $listName, $id, $fileRef) {
  $batch = @"
    <Batch OnError='Continue'>
      <Method ID='1' Cmd='Moderate'>
        <Field Name='ID'>{0}</Field>
        <Field Name='FileRef'>{1}</Field>
        <Field Name='_ModerationStatus'>0</Field>
      </Method>
    </Batch>
"@

  $batch = [xml]($batch -f $id, $fileRef)

  #TODO: Cache proxy by url
  $ls = new-spservice stspub.Services.Lists $serviceUrl
  $updateResults = $ls.UpdateListItems($listName, $batch.Batch)
  if($updateResults.ChildNodes.Count -gt 1) {
      Write-Output $updateResults
      throw ("Unexpected number of child nodes {0}, expected 1" -f $updateResults.ChildNodes.Count)
  }
  
  # ows__ModerationStatus
  #   ref: http://msdn.microsoft.com/en-us/library/dd305114(PROT.13).aspx
  
  return $updateResults.ChildNodes.Item(0)
}

$urlInfo = (resolve-siteurl $documentUrl)
$fileRef = $documentUrl -replace $urlInfo.WebUrl +, ""
if($fileRef.StartsWith("/")) {
  $fileRef = $fileRef.Substring(1)
}

$fileItem = Get-FileListItem $urlInfo.WebUrl $listName $fileRef
Approve-ListItem $urlInfo.WebUrl $listName $fileItem.ows_ID $fileItem.ows_FileRef