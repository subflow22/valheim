$world     = "ForbodulonPrime"
$game_dir  = "$env:USERPROFILE\AppData\LocalLow\IronGate\Valheim"
$save_dir  = "$game_dir\worlds"
$back_dir  = "$game_dir\back"

$files = (Get-ChildItem $back_dir).where({$_.Name -like "$world*"}).Name
foreach ($file in $files)
    {
        Copy-Item -Path "$back_dir\$file" -Destination $save_dir\$file -Force
    }
