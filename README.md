# Gas Mapocho - repositorio principal

Backend de microservicios del proyecto Gas Mapocho (Spring Boot 4.1.1, Spring Cloud 2025.1.3, Java 25).

## Servicios

| Servicio | Puerto | Depende de |
|---|---|---|
| `eureka-server` | 8761 | - |
| `config-server` | 8888 | Eureka, repo `DAW-II_Grupo09_gasmapocho_config-repo` en GitHub |
| `api-gateway` | 8080 | Eureka, Config Server |
| `ms-usuarios` | 8081 | Eureka, Config Server, PostgreSQL |
| `ms-balones` | 8082 | Eureka, Config Server, PostgreSQL, RabbitMQ |
| `ms-movimientos` | 8083 | Eureka, Config Server, PostgreSQL, RabbitMQ, ms-balones (Feign) |
| `ms-reportes` | 8084 | Eureka, Config Server, ms-balones y ms-movimientos (Feign) — sin base propia |

## Como clonar

Cada servicio tiene su propio repositorio en GitHub (cuenta `Sophia-1827`, prefijo `DAW-II_Grupo09_gasmapocho_`).
Este repo (`_principal`) trae el `docker-compose.yml`, los scripts de base de datos y `start-all.ps1`; para que las rutas
funcionen, todos se clonan dentro de una misma carpeta y con el nombre corto de la columna "Carpeta":

| Repo | Carpeta |
|---|---|
| `..._principal` | `principal` |
| `..._eureka-server` | `eureka-server` |
| `..._config-server` | `config-server` |
| `..._config-repo` | `config-repo` (solo lectura: lo lee `config-server` desde GitHub) |
| `..._api-gateway` | `api-gateway` |
| `..._ms-usuarios` | `ms-usuarios` |
| `..._ms-balones` | `ms-balones` |
| `..._ms-movimientos` | `ms-movimientos` |
| `..._ms-reportes` | `ms-reportes` |

```bash
mkdir gas-mapocho && cd gas-mapocho
B=https://github.com/Sophia-1827/DAW-II_Grupo09_gasmapocho
git clone ${B}_principal principal
for s in eureka-server config-server config-repo api-gateway ms-usuarios ms-balones ms-movimientos ms-reportes; do
  git clone ${B}_$s $s
done
```

El frontend (Angular) esta aparte, en `DAW-II_Grupo09_gasmapocho_frontend`.

## Requisitos para correr el proyecto completo

1. **JDK 25** (`JAVA_HOME` apuntando a esa versión).
2. **PostgreSQL** instalado y corriendo en `localhost:5432`.
3. **RabbitMQ** instalado y corriendo en `localhost:5672` (lo usan `ms-balones` y `ms-movimientos` para actualizar el stock de forma asíncrona cuando se registra un movimiento).

## Configurar PostgreSQL

Cada quien tiene su propia copia local de la base — no es una base compartida.
1. Instala PostgreSQL si no lo tienes: https://www.postgresql.org/download/ (durante la instalación te va a pedir una contraseña para el usuario `postgres`, anótala).
2. Abre una terminal y conéctate como `postgres` (te va a pedir la contraseña que pusiste al instalar):
   ```bash
   psql -U postgres -h 127.0.0.1
   ```
3. Dentro de `psql`, crea el rol y las 3 bases del proyecto (copia y pega todo junto, cambia la contraseña por una tuya):
   ```sql
   CREATE ROLE gasmapocho LOGIN PASSWORD 'TuContraseñaAqui';
   CREATE DATABASE gasmapocho_usuarios OWNER gasmapocho;
   CREATE DATABASE gasmapocho_balones OWNER gasmapocho;
   CREATE DATABASE gasmapocho_movimientos OWNER gasmapocho;
   \q
   ```
4. Las tablas y los datos de ejemplo se crean solos la primera vez que corras cada microservicio (Hibernate + un `DataSeeder`), no hay que correr ningún script `.sql` aparte.

## Variables de entorno (antes de correr cualquier microservicio con base de datos)

Cada quien usa su propia contraseña, la que eligió en el paso 3. Nunca se escribe en ningún archivo del repo.

PowerShell:
```powershell
$env:DB_USER="gasmapocho"
$env:DB_PASSWORD="TuContraseñaAqui"
```

Bash:
```bash
export DB_USER=gasmapocho
export DB_PASSWORD='TuContraseñaAqui'
```

Esto vale solo para esa ventana de terminal — hay que volver a setearlo si la cierras.

## Configuracion centralizada (Config Server)

Los servicios solo guardan en su `application.properties` el nombre, el puerto y la direccion de Eureka. El resto
(base de datos, RabbitMQ, rutas del gateway, Circuit Breaker) lo sirve `config-server` desde el repo
`DAW-II_Grupo09_gasmapocho_config-repo`; la carpeta `config-repo` solo hace falta clonarla si se quiere editar.
Por eso hay que arrancar siempre Eureka y luego `config-server`, antes que los demas.

- Usuario y contrasena de PostgreSQL: **no** estan en el repo. Cada quien define `DB_USER` y `DB_PASSWORD` (ver arriba).
- Para probar un cambio de configuracion sin hacer push: `CONFIG_REPO_URI` apunta `config-server` a otra copia del repo.
- Despues de cambiar un archivo del repo de configuracion hay que reiniciar el servicio afectado.

## Orden para levantar todo

```bash
cd eureka-server && ./mvnw spring-boot:run      # esperar a que termine de arrancar
cd config-server && ./mvnw spring-boot:run      # esperar a que termine; los demas leen su configuracion de aqui
cd ms-usuarios && ./mvnw spring-boot:run
cd ms-balones && ./mvnw spring-boot:run
cd ms-movimientos && ./mvnw spring-boot:run
cd ms-reportes && ./mvnw spring-boot:run
cd api-gateway && ./mvnw spring-boot:run        # al final, cuando los demas ya esten registrados en Eureka
```

Eureka tarda ~30 segundos en propagar un registro nuevo a los demás servicios, así que si algo da 503/500 justo después de arrancar, espera un poco y reintenta.

## Correr todo con Docker (alternativa a instalar todo a mano)

Hay un `docker-compose.yml` en este repo (se ejecuta desde la carpeta `principal`) que levanta los 6 microservicios + PostgreSQL + RabbitMQ con un solo comando, sin instalar nada más que Docker Desktop:

Antes crea tu archivo `.env` a partir de la plantilla y pon tu propia contraseña (el `.env` no se sube a GitHub):

```bash
cp .env.example .env
docker compose up --build
```

La primera vez tarda varios minutos (compila cada servicio con Maven dentro del contenedor). `api-gateway` queda en `http://localhost:8080` y `postgres`/`rabbitmq` quedan accesibles igual que si estuvieran instalados localmente. **Nota**: esto todavía no se probó en vivo en ningún equipo del grupo (Docker Desktop no arrancó en esta PC durante el desarrollo) — probarlo antes de depender de esto para la sustentación.

## Usuarios de prueba (sembrados automáticamente)

| email | password | rol |
|---|---|---|
| admin@gasmapocho.cl | Admin123 | ADMIN |
| almacen@gasmapocho.cl | Almacen123 | ALMACEN |

## Datos de ejemplo

Además de los usuarios, la primera vez que corre cada servicio se siembran:

- `ms-balones`: 4 balones (BAL-5, BAL-11, BAL-15, BAL-45 con stock 40/30/20/10) y 3 proveedores.
- `ms-movimientos`: 3 clientes y 12 movimientos de los últimos días (compras a proveedor, ventas, y uno de cada estado).

Los seeders solo escriben si la tabla está vacía. Para volver a este estado inicial (por ejemplo después de probar), con los servicios apagados, ejecuta en PostgreSQL:

```sql
-- en la base gasmapocho_movimientos
TRUNCATE movimiento, cliente RESTART IDENTITY;
-- en la base gasmapocho_balones
UPDATE balon SET stock = CASE codigo WHEN 'BAL-5' THEN 40 WHEN 'BAL-11' THEN 30 WHEN 'BAL-15' THEN 20 WHEN 'BAL-45' THEN 10 END;
```

y vuelve a levantar `ms-movimientos`.
