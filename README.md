# UWUnimia

UwUnimia utilizza un classico Pattern MVC utilizzando
[Slim](https://www.slimframework.com/), ma solo con l'utilizzo di
librerie di terze parti per la gestione delle richieste HTTP e per la
gestione del database.

Repository Disponibile su
[GitHub](https://github.com/heph2/uwunimia)

## Requisiti

- PHP 7.4
- Composer
- PostgreSQL 14
- Docker Compose

## Installazione

Installare le dipendenze con composer

```bash
composer install
```

Ed infine lanciare le migrazioni e i seeders

```bash
composer migrate && composer seed
```

Possiamo avere un ambiente di demo semplicemente lanciando

```bash
docker compose up -d
```

Dopodiche dobbiamo semplicemente importare il dump con:

```bash
docker exec -u postgres uwunimia-db-1 psql postgres postgres -d test -f docker-entrypoint-initdb.d/dump.sql
```

A questo punto abbiamo l'applicativo disponibile in http://localhost:8080

## Utilizzo

Possiamo direttamente utilizzare il server di sviluppo di PHP

```bash
composer start
```

Inoltre UwUnimia proverá a loggare utilizzando Monolog su un file di log, per visualizzare i log possiamo utilizzare il comando

```bash
tail -f var/log/app.log
```

## Struttura Progetto

```
src
    Actions -> Gestione Logica delle richieste HTTP
    Models -> Gestione della logica di "business" (AKA accesso al database)
    Middleware -> Gestione delle richieste HTTP prima di arrivare al controller

templates -> Gestione HTML con Twig (Template Engine)

db 
    migrations -> Migrazioni del database
    seeds -> Seeders del database

public -> File pubblici

config -> Dependency Injection e configurazioni
docs -> Documentazione varia (Schema ER/Logico)

```

## Rilascio

Possiamo generare un dump del db e un tar lanciando
    
```bash
composer release
```

## License

See [LICENSE](LICENSE)
