# Levanta todo el backend en orden correcto, esperando a que cada pieza este lista.
# Requiere: PostgreSQL y RabbitMQ ya corriendo, y las variables de entorno DB_USER/DB_PASSWORD
# (o usa -Dspring-boot.run.profiles=local si ya tienes application-local.properties en cada servicio).

$ErrorActionPreference = "Stop"
# Los servicios estan en carpetas hermanas de esta (ver "Como clonar" en el README)
$root = Split-Path $PSScriptRoot -Parent
$javaHome = "C:\Program Files\Java\jdk-25.0.4"
$env:JAVA_HOME = $javaHome

function Start-Servicio($nombre, $puerto) {
    Write-Host "Iniciando $nombre..." -ForegroundColor Cyan
    $dir = Join-Path $root $nombre
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d `"$dir`" && mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=local" -WindowStyle Minimized
    $intentos = 0
    while ($intentos -lt 40) {
        Start-Sleep -Seconds 2
        try {
            $resp = Invoke-WebRequest -Uri "http://localhost:$puerto/" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            break
        } catch {
            if ($_.Exception.Response) { break }  # respondio con error HTTP = ya esta arriba
        }
        $intentos++
    }
    Write-Host "$nombre listo en el puerto $puerto" -ForegroundColor Green
}

# verificar PostgreSQL y RabbitMQ
$pg = Get-Service postgresql-x64-18 -ErrorAction SilentlyContinue
$rmq = Get-Service RabbitMQ -ErrorAction SilentlyContinue
if ($pg.Status -ne "Running") { Write-Host "ADVERTENCIA: PostgreSQL no esta corriendo" -ForegroundColor Yellow }
if ($rmq.Status -ne "Running") { Write-Host "ADVERTENCIA: RabbitMQ no esta corriendo" -ForegroundColor Yellow }

Start-Servicio "eureka-server" 8761
Start-Servicio "config-server" 8888
Start-Servicio "ms-usuarios" 8081
Start-Servicio "ms-balones" 8082
Start-Servicio "ms-movimientos" 8083
Start-Servicio "ms-reportes" 8084

Write-Host "Esperando ~35s a que Eureka propague los registros antes de levantar el Gateway..." -ForegroundColor Cyan
Start-Sleep -Seconds 35

Start-Servicio "api-gateway" 8080

Write-Host "`nTodo arriba. Gateway: http://localhost:8080" -ForegroundColor Green
Write-Host "Eureka (ver servicios registrados): http://localhost:8761" -ForegroundColor Green
