# BUILD EOP Script
$currentLoc=(get-location).path

# Colors
# https://duffney.io/usingansiescapesequencespowershell/
$color = "`e[$(35)m"
$endColor = "`e[0m`e[30;"

function CopyFilesToFolder ($fromFolder, $toFolder) {
    $childItems = Get-ChildItem $fromFolder
    $childItems | ForEach-Object {
         Copy-Item -Path $_.FullName -Destination $toFolder -Recurse -Force
    }
}

Write-Output "$color======== 0) Pre Cleanup ======== $endColor"


Set-Location -Path $currentLoc
Remove-item ./logs -recurse -erroraction 'silentlycontinue'
new-item ./logs -itemtype directory -erroraction 'silentlycontinue'

# 1) Build M2TWEOP-library
Write-Output "$color======== 1) Build M2TWEOP-library ======== $endColor"

devenv  "M2TWEOP-library\M2TWEOP library.sln" /build "Release|x86" /project "M2TWEOP library" /out "logs\library.log"
devenv  "M2TWEOP-library\M2TWEOP library.sln" /build "Release|x86" /project "M2TWEOP GUI" /out "logs\GUI.log"
devenv  "M2TWEOP-library\M2TWEOP library.sln" /build "Release|x86" /project "M2TWEOP tools"  /out "logs\tools.log"
devenv  "M2TWEOP-library\M2TWEOP library.sln" /build "Release|x86" /project "d3d9"  /out "logs\d3d9.log"

# 2) Build M2TWEOP-LuaPlugin
Write-Output "$color======== 2) Build M2TWEOP-LuaPlugin ======== $endColor"

devenv  "M2TWEOP-luaPlugin\luaPlugin.sln" /build "Release|x86" /project "luaPlugin"  /out "logs\luaPlugin.log"

# 3) Build Documentation
Write-Output "$color======== 3) Build M2TWEOP-Documentation ======== $endColor"

cd "documentationGenerator"
&".\generateDocs.ps1"   -Wait -NoNewWindow | Write-Verbose

# 4) Copy built files
Write-Output "$color======== 4) Copy all created files ======== $endColor"

Set-Location -Path $currentLoc
Remove-item ./M2TWEOPGenerated -recurse -erroraction 'continue'
new-item ./M2TWEOPGenerated  -itemtype directory -erroraction 'continue'

Copy-Item -Path  "M2TWEOP-DataFiles\*" -Destination "./M2TWEOPGenerated" -recurse

Get-ChildItem -Path "documentationGenerator\EOPDocs\build\html\*" -erroraction 'continue'
CopyFilesToFolder "documentationGenerator\EOPDocs\build\html" "./M2TWEOPGenerated/eopData/helpPages"

Copy-Item -Path  "M2TWEOP-luaPlugin\Release\luaPlugin.dll" -Destination "./M2TWEOPGenerated/youneuoy_Data/plugins" -erroraction 'continue'
Copy-Item -Path  "M2TWEOP-library\Release\d3d9.dll" -Destination "./M2TWEOPGenerated" -erroraction 'continue'
Copy-Item -Path  "M2TWEOP-library\Release\M2TWEOP GUI.exe" -Destination "./M2TWEOPGenerated" -erroraction 'continue'
Copy-Item -Path  "M2TWEOP-library\Release\M2TWEOP tools.exe" -Destination "./M2TWEOPGenerated" -erroraction 'continue'
Copy-Item -Path  "M2TWEOP-library\Release\M2TWEOPLibrary.dll" -Destination "./M2TWEOPGenerated" -erroraction 'continue'

# 5) Generate Release ZIP
Write-Output "$color======== 5) Generate Release ZIP ======== $endColor"
Remove-item M2TWEOP.zip -erroraction 'continue'
Compress-Archive -Path "./M2TWEOPGenerated/*"  -DestinationPath "M2TWEOP.zip" -erroraction 'continue'
Remove-item ./M2TWEOPGenerated -recurse -erroraction 'continue'

# 6) Done
Write-Output "$color======== 6) Success! EOP Built Successfully! ======== $endColor"