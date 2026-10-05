param(
    [string]$Port = 'COM6',
    [int]$Seconds = 90,
    [string]$OutFile,
    [switch]$SendEnter,      # spam CR until the MStar prompt shows up
    [string[]]$Commands = @() # sent one by one once the prompt is seen
)
$sp = New-Object System.IO.Ports.SerialPort $Port, 115200, 'None', 8, 'One'
$sp.ReadTimeout = 100
$sp.DtrEnable = $true
$sp.RtsEnable = $true
try { $sp.Open() } catch { Write-Output "OPEN_FAILED: $($_.Exception.Message)"; exit 1 }
Write-Output "OPEN_OK $Port"
$fs = [System.IO.File]::Open($OutFile, 'Create', 'Write', 'Read')
$buf = New-Object byte[] 4096
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$total = 0
$text = ''
$prompt = $false
$lineStart = $true
$cmdIdx = 0
$lastSend = 0
$lastRx = 0
while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    $n = 0
    try { $n = $sp.Read($buf, 0, $buf.Length) } catch [System.TimeoutException] { }
    if ($n -gt 0) {
        $fs.Write($buf, 0, $n); $fs.Flush()
        # second file: same data with seconds-since-start at each line start
        $sb = New-Object System.Text.StringBuilder
        for ($i = 0; $i -lt $n; $i++) {
            $b = $buf[$i]
            if ($b -eq 13) { continue }
            if ($lineStart) { [void]$sb.Append(('[{0,7:F2}s] ' -f $sw.Elapsed.TotalSeconds)); $lineStart = $false }
            if ($b -eq 10) { [void]$sb.Append("`r`n"); $lineStart = $true }
            elseif ($b -ge 32 -and $b -lt 127) { [void]$sb.Append([char]$b) }
            else { [void]$sb.Append(('<{0:X2}>' -f $b)) }
        }
        [System.IO.File]::AppendAllText($OutFile + '.zeit.txt', $sb.ToString())
        $total += $n
        $lastRx = $sw.ElapsedMilliseconds
        $text += [System.Text.Encoding]::ASCII.GetString($buf, 0, $n)
        if ($text.Length -gt 400) { $text = $text.Substring($text.Length - 400) }
        if ($text -match 'MStar >>#\s*$') { $prompt = $true }
    }
    if ($SendEnter -and -not $prompt -and ($sw.ElapsedMilliseconds - $lastSend) -gt 50) {
        $sp.Write("`r"); $lastSend = $sw.ElapsedMilliseconds
    }
    # prompt seen and line quiet for 700 ms -> send next command
    if ($prompt -and $cmdIdx -lt $Commands.Count -and ($sw.ElapsedMilliseconds - $lastRx) -gt 700 -and ($sw.ElapsedMilliseconds - $lastSend) -gt 700) {
        $sp.Write($Commands[$cmdIdx] + "`r"); $cmdIdx++
        $lastSend = $sw.ElapsedMilliseconds
        $text = ''
    }
    if ($prompt -and $cmdIdx -ge $Commands.Count -and $Commands.Count -gt 0 -and ($sw.ElapsedMilliseconds - $lastRx) -gt 4000) { break }
}
$fs.Close(); $sp.Close()
Write-Output "DONE bytes=$total prompt=$prompt cmds_sent=$cmdIdx"
