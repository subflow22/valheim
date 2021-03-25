$world_name  = "world_name"
$world_path  = "$env:USERPROFILE\AppData\LocalLow\IronGate\Valheim\worlds\$world_name.fwl"
$string = (Get-Content "$world_path")
$pattern = '[^a-zA-Z0-9]'
($string -replace $pattern, ' ').Replace(' ','')