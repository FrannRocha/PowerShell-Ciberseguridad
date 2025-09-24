# Editado por by franana el 23/09/2025
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Clear-Host

try {
    Import-Module AuditoriaBasica -Force
} catch {
    Write-Host "No se pudo importar el modulo. Ejecuta como admin y verifica la ruta."
    exit 1
}

$carpetaSalida = Read-Host "Carpeta de salida (Enter para Escritorio)"
if ([string]::IsNullOrWhiteSpace($carpetaSalida)) {
    $carpetaSalida = Join-Path $env:USERPROFILE 'Desktop'
}
if (-not (Test-Path $carpetaSalida)) {
    try { New-Item -Path $carpetaSalida -ItemType Directory -Force | Out-Null } catch {
        Write-Host "No se pudo crear la carpeta de salida."
        exit 1
    }
}

function Mostrar-Menu {
    Write-Host "=== Auditoria basica de usuarios y servicios ==="
    Write-Host "1. Mostrar usuarios inactivos"
    Write-Host "2. Mostrar servicios externos activos"
    Write-Host "3. Salir"
}

do {
    Mostrar-Menu
    $opcion = Read-Host "Selecciona una opcion (1-3)"
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

    switch ($opcion) {
        '1' {
            try {
                $usuarios = Obtener-UsuariosInactivos
                if (-not $usuarios) {
                    Write-Host "No se encontraron usuarios inactivos."
                    continue
                }

                $usuarios | Format-Table Name, Enabled, LastLogon -AutoSize

                $csv = Join-Path $carpetaSalida ("users_inactivos_{0}.csv" -f $timestamp)
                $usuarios | Select-Object Name, Enabled, LastLogon |
                    Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

                Write-Host ""
                Write-Host "Reporte CSV generado: $csv"
            } catch {
                Write-Host "Error al obtener usuarios: $($_.Exception.Message)"
            }
        }
        '2' {
            try {
                $servicios = Obtener-ServiciosExternos
                if (-not $servicios) {
                    Write-Host "No se encontraron servicios externos activos."
                    continue
                }

                $servicios | Format-Table DisplayName, Status, StartType -AutoSize

                $html = Join-Path $carpetaSalida ("servicios_externos_{0}.html" -f $timestamp)
                $servicios |
                    Select-Object DisplayName, Status, ServiceName, StartType |
                    ConvertTo-Html -Title 'Servicios externos activos' |
                    Out-File -FilePath $html -Encoding UTF8

                Write-Host ""
                Write-Host "Reporte HTML generado: $html"
            } catch {
                Write-Host "Error al obtener servicios: $($_.Exception.Message)"
            }
        }
        '3' { Write-Host "Saliendo..." }
        default { Write-Host "Opcion no valida." }
    }
    Write-Host ""
} while ($opcion -ne '3')
