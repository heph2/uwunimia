<?php
namespace UwUnimia\Action;

use Psr\Container\ContainerInterface;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

abstract class BaseAction
{
    protected $view;
    protected $logger;
    protected $pdo;

    public function __construct(ContainerInterface $container)
    {
        $this->view = $container->get('view');
        $this->pdo = $container->get('pdo');
        $this->logger = $container->get('logger');
    }

    protected function render(Request $request, Response $response, string $template, array $params = []): Response
    {
        return $this->view->render($response, $template, $params);
    }
}
