Add-Type -AssemblyName System.Windows.Forms
function RandomPassword {
    $chars = "0123456789"
    $result = ""
    for ($i = 0; $i -lt 4; $i++) {
        $result += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $result
}
function Get-BlockedIP {
    if (Test-Path "ip.txt") {
        return Get-Content "ip.txt"
    } else {
        return @()
    }
}
function Add-BlockedIP {
    param(
        [string]$IPAddress
    )
    
    $blockedIPs = Get-BlockedIP
    if ($IPAddress -notin $blockedIPs) {
        $blockedIPs += $IPAddress
        "`n" + $blockedIPs | Out-File "ip.txt"
        Write-Host "- $IPAddress Blocked"
    }
}
function Test-BlockedIP {
    param(
        [string]$IPAddress
    )
    
    $blockedIPs = Get-BlockedIP
    return $IPAddress -in $blockedIPs
}

if (Test-Path "pass.txt") {
    $currentPassword = Get-Content "pass.txt" -Raw
    $currentPassword = $currentPassword.Trim()
} else {
    $currentPassword = RandomPassword
    $currentPassword | Out-File "pass.txt" -NoNewline
}
$blockedIPs = Get-BlockedIP
Write-Host $($blockedIPs -join ', ')
$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 2323)
$listener = New-Object System.Net.Sockets.TcpListener $endpoint
try {
    $listener.Start()
    Write-Host "running  -> 2323 ON, pass -> $currentPassword"
    
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $clientIP = $client.Client.RemoteEndPoint.Address.ToString()
        Write-Host "+ Target: $clientIP"
        
        if (Test-BlockedIP -IPAddress $clientIP) {
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.WriteLine("Access denied >_<")
            $writer.Flush()
            $writer.Close()
            $client.Close()
            continue
        }
        
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)
        
        $writer.WriteLine([char]27 + "[31mLogin Admin" + [char]27 + "[0m")
        $writer.Flush()
        
        $writer.WriteLine("Enter Password :")
        $writer.Flush()
        $clientPassword = $reader.ReadLine()
        
        if ($clientIP -eq "192.168.1.7"){
            $writer.WriteLine("Welcome")
            $writer.Flush()
        } else {
            if ($clientPassword -eq $currentPassword) {
                Add-BlockedIP -IPAddress $clientIP
                
                $currentPassword = RandomPassword
                $currentPassword | Out-File "pass.txt" -NoNewline
                Write-Host "+ new password : $currentPassword"
    
                $writer.WriteLine("")
                $writer.Flush()
                $writer.WriteLine("#_# ---| Very unfaithful")
                $writer.Flush()
            
            } else {
                $writer.WriteLine("Not Access")
                $writer.Flush()
            }
        }
        
        $reader.Close()
        $writer.Close()
        $client.Close()
    }
}
finally {
    $listener.Stop()
    Write-Host "stoped"
}
