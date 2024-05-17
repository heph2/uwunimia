<?php

use Psr\Container\ContainerInterface;
use Monolog\Handler\StreamHandler;
use Monolog\Logger;
use Monolog\Processor\UidProcessor;
use Slim\App;
use Slim\Factory\AppFactory;
use Slim\Views\Twig;

return [
    'settings' => function () {
        return require __DIR__ . '/settings.php';
    },

    'logger' => function (ContainerInterface $container) {
        $settings = $container->get('settings');

        $loggerSettings = $settings['logger'];
        $logger = new Logger($loggerSettings['name']);

        $processor = new UidProcessor();
        $logger->pushProcessor($processor);

        $handler = new StreamHandler($loggerSettings['path'], $loggerSettings['level']);
        $logger->pushHandler($handler);

        return $logger;
    },

    'view' => function (ContainerInterface $container) {
        $settings = $container->get('settings');
        return Twig::create($settings['view']['template_path'], $settings['view']['twig']);
    },

    'twig_profile' => function () {
        return new \Twig\Profiler\Profile();
    },

    'pdo' => function (ContainerInterface $container) {
        $settings = $container->get('settings');

        $host = $settings['db']['host'];
        $dbname = $settings['db']['database'];
        $username = $settings['db']['username'];
        $password = $settings['db']['password'];
        $charset = $settings['db']['charset'];
        $flags = $settings['db']['flags'];
        $dsn = "pgsql:host=$host;port=5432;dbname=$dbname";
        $pdo = new PDO($dsn, $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $pdo;
    },

    App::class => function (ContainerInterface $container) {
        AppFactory::setContainer($container);

        $app = AppFactory::create();

        // Register routes
        (require __DIR__ . '/routes.php')($app);

        // Register middleware
        (require __DIR__ . '/middleware.php')($app);

        return $app;
    },
];
