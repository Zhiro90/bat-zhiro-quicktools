param(
    [Parameter(ValueFromRemainingArguments = $true)]
    $Files
)

$bat = Join-Path $PSScriptRoot "joinvert_real.bat"

& $bat @Files