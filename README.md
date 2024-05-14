# Lampredotto

Lampredotto utilizza un classico Pattern MVC senza l'utilizzo di framework esterni, ma solo con l'utilizzo di librerie di terze parti per la gestione delle richieste HTTP e per la gestione del database.

Repository Disponibile su [GitHub](https://github.com/heph2/lampredotto) e Demo al segeuente [Link](https://lampredotto.heph2.dev)

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
A questo punto possiamo lanciare postgres

```bash
docker-compose up -d
```
Ed infine lanciare le migrazioni e i seeders

```bash
composer migrate && composer seed
```

## Utilizzo

Possiamo direttamente utilizzare il server di sviluppo di PHP, ma prima dobbiamo generare i css con TailwindCSS

```bash
tailwindcss -i src/templates/css/input.css -o public/css/output.css
```

```bash
composer start
```

Inoltre Lampredotto proverá a loggare utilizzando Monolog su un file di log, per visualizzare i log possiamo utilizzare il comando

```bash
tail -f var/log/app.log
```

## Struttura Progetto

```
src
    Controllers -> Gestione Logica delle richieste HTTP
    Models -> Gestione della logica di "business" (AKA accesso al database)
    Middleware -> Gestione delle richieste HTTP prima di arrivare al controller

templates -> Gestione HTML con Twig (Template Engine)
    css -> TailwindCSS

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
