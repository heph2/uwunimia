<?php

use Monolog\Logger;
use Dotenv\Dotenv;

// Load .env file
// $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv = Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

// Should be set to 0 in production
error_reporting(E_ALL);

// Should be set to '0' in production
ini_set('display_errors', '1');

$debug = true;

// Settings
$settings = [

    // monolog settings
    'logger' => [
        'name' => 'app',
        'path' =>  '../var/log/app.log',
        'level' => $debug ? Logger::DEBUG : Logger::INFO,
    ],
    // View settings
    'view' => [
        'template_path' => '../templates',
        'twig' => [
            'cache' => '../var/cache/twig',
            'debug' => true,
            'auto_reload' => true,
        ],
    ],
    "db" => [
        'driver' => 'pgsql',
        'host' => $_ENV['DB_HOST'],
        'username' => $_ENV['DB_USERNAME'],
        'database' => $_ENV['DB_DATABASE'],
        'password' => $_ENV['DB_PASSWORD'],
        'charset' => 'utf8mb4',
        'collation' => 'utf8mb4_unicode_ci',
        'flags' => [
            // Turn off persistent connections
            PDO::ATTR_PERSISTENT => false,
            // Enable exceptions
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            // Emulate prepared statements
            PDO::ATTR_EMULATE_PREPARES => true,
            // Set default fetch mode to array
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ],
    ],
    "phinx" => [
        'paths' => [
            'migrations' => './db/migrations',
            'seeds' => './db/seeds',
        ],
        'environments' => [
            'default_migration_table' => 'phinxlog',
            'default_environment' => 'development',
            'production' => [
                'adapter' => 'mysql',
                'host' => 'localhost',
                'name' => 'production_db',
                'user' => 'root',
                'pass' => '',
                'port' => '3306',
                'charset' => 'utf8',
            ],
            'development' => [
                'adapter' => 'pgsql',
                'host' => 'localhost',
                'name' => 'test',
                'user' => 'postgres',
                'pass' => 'postgres',
                'port' => '5432',
                'charset' => 'utf8',
            ],
        ],
        'version_order' => 'creation'
    ]
];

return $settings;
