# This scripted is based on the documentation retrieved on 2022-01-03 
# https://community.webcon.com/articles/security-apache-solr-affected-by-apache-log4j-cve-2021-44228/39

# Only this variable needs to be changed to the latest version:
$fileUrl = "https://dlcdn.apache.org/logging/log4j/2.17.1/apache-log4j-2.17.1-bin.zip"

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal -ne $null -and !$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    throw "Must be executed as admin"
}

# Prepare variables
$ErrorActionPreference = "Stop"
$filename = $fileUrl.Substring($fileUrl.LastIndexOf("/")+1)
$log4jFolder = "$($env:TEMP)\Log4J"
$downloadFile = "$log4jFolder\$filename"
$log4jExtractedFolder = "$log4jFolder\$($filename.Replace(".zip",''))"
$solrContribFolder = "$env:ProgramFiles\WEBCON\WEBCON BPS Search Server\Search Cluster\Solr\contrib\prometheus-exporter\lib\"
$solrServerFolder = "$env:ProgramFiles\WEBCON\WEBCON BPS Search Server\Search Cluster\Solr\server\lib\ext\"
$log4j1_2ApiFilePattern = "log4j-1.2-api-2.*.jar"
$log4jApiFilePattern = "log4j-api-2.*.jar"
$log4jCoreFilePattern = "log4j-core-2.*.jar"
$log4jSlf4jFilePattern = "log4j-slf4j-impl-2.*.jar"
$log4jWebFilePattern = "log4j-web-2.*.jar"
Write-Host "Creating log4j folder in temp directory $log4jFolder"
New-Item -Path $log4Jfolder -ItemType Directory -Force |Out-Null

# Step 1 downloading
Write-Host "Downloading file: '$downloadFile'"
Invoke-WebRequest -Uri $fileUrl -OutFile $downloadFile
Write-Host "Extracting file: '$downloadFile'"
Expand-Archive -Path $downloadFile -DestinationPath $log4jFolder -Verbose -Force
Get-ChildItem -Path $log4jExtractedFolder -Filter "*-javadoc.jar" | Remove-Item
Get-ChildItem -Path $log4jExtractedFolder -Filter "*-sources.jar"| Remove-Item

# Step 2 stop search
Stop-Service "Webcon BPS Search Service" -Verbose
# Step 3 delete files
Write-Host "Going to delete the old files $log4jApiFilePattern, $log4jCoreFilePattern, $log4jSlf4jFilePattern  from contrib folder`r`n please confirm that the correct file will be deleted."
Get-ChildItem $solrContribFolder  -Filter $log4jApiFilePattern | Remove-Item -Confirm
Get-ChildItem $solrContribFolder  -Filter $log4jCoreFilePattern | Remove-Item -Confirm
Get-ChildItem $solrContribFolder  -Filter $log4jSlf4jFilePattern | Remove-Item -Confirm

# Step 5/6 copy new files
Write-Host "Copying new items to contrib folder"
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jApiFilePattern | Copy-Item -Destination $solrContribFolder #-Confirm
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jCoreFilePattern | Copy-Item -Destination $solrContribFolder #-Confirm
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jSlf4jFilePattern | Copy-Item -Destination $solrContribFolder #-Confirm

#Step 4 delete old files with confirmation
Write-Host "Going to delete the old files $log4j1_2ApiFilePattern, $log4jApiFilePattern, $log4jCoreFilePattern, $log4jSlf4jFilePattern, $log4jWebFilePattern from server folder`r`n please confirm that the correct file will be deleted."
Get-ChildItem $solrServerFolder  -Filter $log4j1_2ApiFilePattern | Remove-Item -Confirm
Get-ChildItem $solrServerFolder  -Filter $log4jApiFilePattern | Remove-Item -Confirm
Get-ChildItem $solrServerFolder  -Filter $log4jCoreFilePattern | Remove-Item -Confirm
Get-ChildItem $solrServerFolder  -Filter $log4jSlf4jFilePattern | Remove-Item -Confirm
Get-ChildItem $solrServerFolder  -Filter $log4jWebFilePattern | Remove-Item -Confirm

# Step 7/8 copy new files
Write-Host "Copying new items to server folder"
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4j1_2ApiFilePattern | Copy-Item -Destination $solrServerFolder #-Confirm
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jApiFilePattern | Copy-Item -Destination $solrServerFolder #-Confirm
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jCoreFilePattern | Copy-Item -Destination $solrServerFolder #-Confirm
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jSlf4jFilePattern | Copy-Item -Destination $solrServerFolder #-Confirm
Get-ChildItem -Path $log4jExtractedFolder -Filter $log4jWebFilePattern | Copy-Item -Destination $solrServerFolder #-Confirm

# Step 9 start search
Start-Service "Webcon BPS Search Service" -Verbose
# Step 10 verification
write-host "Verify whether the search server functions correctly by e.g. opening the following in a browser"
Sleep -Seconds 10 
Start-Process "http://localhost:8983"
Start-Process "http://localhost:8983/solr/BPS_Activities/query?q=*&rows=1"
Start-Process "http://localhost:8983/solr/BPS_Elements/query?q=*&rows=1"