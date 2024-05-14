<?php

namespace UwUnimia\Middleware;

use Psr\Http\Message\ResponseInterface as Response;

class SessionMiddleware
{
    /**
     * Example middleware invokable class
     *
     * @param  \Psr\Http\Message\ServerRequestInterface $request  PSR7 request
     * @param  \Psr\Http\Message\ResponseInterface      $response PSR7 response
     * @param  callable                                 $next     Next middleware
     *
     * @return \Psr\Http\Message\ResponseInterface
     */
    public function __invoke($request, $next)
    {
        error_log("SessionMiddleware invoked!");
        if (!isset($_SESSION['user'])) {
            error_log("Session not set");
            $psr17Factory = new \Nyholm\Psr7\Factory\Psr17Factory();
            $response = $psr17Factory->createResponse(302)->withHeader('Location', '/login');
            return $response;
        }

        $response = $next->handle($request);
        return $response;
    }
}
