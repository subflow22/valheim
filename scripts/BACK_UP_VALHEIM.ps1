$world     = "world_name"
$game_dir  = "$env:USERPROFILE\AppData\LocalLow\IronGate\Valheim"
$save_dir  = "$game_dir\worlds"
$back_dir  = "$game_dir\back"

if (!(Test-Path $back_dir))
    {
        New-Item -ItemType Directory -Path $back_dir -Force
    }

$files = (Get-ChildItem $save_dir).where({$_.Name -like "$world*"}).Name
foreach ($file in $files)
    {
        Copy-Item -Path "$save_dir\$file" -Destination $back_dir\$file -Force
    }
