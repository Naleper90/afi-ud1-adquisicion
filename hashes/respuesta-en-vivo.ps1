<#
.SYNOPSIS
    Respuesta en vivo en Windows: recoge los datos volátiles del sistema en el orden
    de volatilidad y calcula el SHA-256 de cada fichero generado.

.DESCRIPTION
    Análisis Forense Informático · UD1 · IES Rafael Alberti · CC BY-SA 4.0

    - Ejecútalo DESDE TU USB, en una consola de PowerShell abierta como administrador.
    - Todo se escribe en el USB; nada en el disco del equipo investigado.
    - No sustituye al volcado de memoria: haz primero el volcado (DumpIt, WinPmem…)
      y después lanza este script.
    - Usa PowerShell y comandos del propio sistema. Si sospechas que el sistema está
      comprometido, anótalo: sus binarios podrían estar manipulados.

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File E:\herramientas\respuesta-en-vivo.ps1 -Caso CASO-042 -Evidencia PC01
#>
param(
    [Parameter(Mandatory = $true)] [string] $Caso,
    [Parameter(Mandatory = $true)] [string] $Evidencia,
    [string] $Destino = (Join-Path $PSScriptRoot 'salida')
)

$ErrorActionPreference = 'Continue'
$inicio  = Get-Date
$carpeta = Join-Path $Destino ("{0}_{1}_{2:yyyyMMdd-HHmmss}" -f $Caso, $Evidencia, $inicio.ToUniversalTime())
New-Item -ItemType Directory -Path $carpeta -Force | Out-Null
$registro = Join-Path $carpeta '00-registro.txt'

function Escribe-Registro([string] $texto) {
    $linea = '{0:yyyy-MM-dd HH:mm:ss}Z  {1}' -f (Get-Date).ToUniversalTime(), $texto
    Add-Content -Path $registro -Value $linea -Encoding UTF8
    Write-Host $linea
}

# Ejecuta un bloque, guarda su salida en un fichero numerado y lo anota en el registro
function Recoge([string] $nombre, [scriptblock] $bloque) {
    $fichero = Join-Path $carpeta "$nombre.txt"
    Escribe-Registro "INICIO $nombre"
    try {
        $salida = & $bloque 2>&1 | Out-String -Width 4096
        Escribe-Registro "FIN    $nombre"
    } catch {
        # Un comando que no existe en esta edición de Windows no debe parar la recogida
        $salida = "ERROR: $($_.Exception.Message)"
        Escribe-Registro "ERROR  $nombre : $($_.Exception.Message)"
    }
    Set-Content -Path $fichero -Value $salida -Encoding UTF8
}

Escribe-Registro "Caso $Caso · evidencia $Evidencia · equipo $env:COMPUTERNAME · usuario $env:USERDOMAIN\$env:USERNAME"
Escribe-Registro ("Hora local {0:yyyy-MM-dd HH:mm:ss} · zona {1} · desfase UTC {2}" -f $inicio, [TimeZoneInfo]::Local.Id, [TimeZoneInfo]::Local.GetUtcOffset($inicio))
Escribe-Registro "Anota en el acta la diferencia entre este reloj y la hora real."

# --- 1. Estado del sistema y sesiones ------------------------------------------
Recoge '01-fecha-hora'        { Get-Date; Get-TimeZone }
Recoge '01b-sincronizacion'   { w32tm /query /status }
Recoge '02-arranque'          { Get-CimInstance Win32_OperatingSystem | Select-Object CSName, Caption, Version, InstallDate, LastBootUpTime }
Recoge '03-sesiones'          { query user; Get-CimInstance Win32_LogonSession | Select-Object LogonId, LogonType, StartTime }

# --- 2. Red: lo que más rápido cambia -----------------------------------------
Recoge '04-conexiones-tcp'    { Get-NetTCPConnection | Sort-Object State | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess, CreationTime | Format-Table -AutoSize }
Recoge '05-puertos-udp'       { Get-NetUDPEndpoint | Select-Object LocalAddress, LocalPort, OwningProcess, CreationTime | Format-Table -AutoSize }
Recoge '06-netstat'           { netstat -anob }
Recoge '07-cache-arp'         { arp -a }
Recoge '08-cache-dns'         { ipconfig /displaydns }
Recoge '09-rutas'             { route print }
Recoge '10-configuracion-red' { ipconfig /all }
Recoge '11-recursos-compartidos' { Get-SmbShare; Get-SmbSession; Get-SmbConnection }

# --- 3. Procesos y lo que se ejecuta -------------------------------------------
Recoge '12-procesos'          { Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId, Name, CreationDate, ExecutablePath, CommandLine | Format-List }
Recoge '13-servicios'         { Get-CimInstance Win32_Service | Select-Object Name, State, StartMode, StartName, PathName | Format-Table -AutoSize }
Recoge '14-tareas-programadas'{ schtasks /query /fo LIST /v }
Recoge '15-inicio-automatico' { Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-List }

# --- 4. Usuarios, dispositivos y sistema --------------------------------------
Recoge '16-usuarios-locales'  { Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet }
Recoge '16b-administradores'  { net localgroup (Get-LocalGroup -SID 'S-1-5-32-544').Name }   # grupo Administradores en cualquier idioma
Recoge '17-discos-volumenes'  { Get-Disk; Get-Volume; Get-BitLockerVolume -ErrorAction SilentlyContinue }
Recoge '18-usb-conectados'    { Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' } | Select-Object FriendlyName, InstanceId, Status }
Recoge '19-portapapeles'      { Get-Clipboard -ErrorAction SilentlyContinue }

# --- 5. Hash de todo lo generado ----------------------------------------------
Escribe-Registro 'Calculando SHA-256 de los ficheros generados'
Get-ChildItem -Path $carpeta -File |
    Where-Object { $_.Name -notin 'hashes-sha256.csv', '00-registro.txt' } |
    Get-FileHash -Algorithm SHA256 |
    Select-Object @{n='Fichero'; e={ Split-Path $_.Path -Leaf }}, Hash |
    Export-Csv -Path (Join-Path $carpeta 'hashes-sha256.csv') -NoTypeInformation -Encoding UTF8

$fin = Get-Date
Escribe-Registro ("Terminado en {0:N0} s. Salida: {1}" -f ($fin - $inicio).TotalSeconds, $carpeta)
Write-Host ''
Write-Host "Calcula ahora el hash del propio registro y anótalo en el acta:" -ForegroundColor Yellow
Write-Host "  Get-FileHash '$registro' -Algorithm SHA256"
