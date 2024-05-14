<?php

namespace UwUnimia\Middleware;

class RbacMiddleware
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
        error_log("RBAC invoked");
        $userRole = "/" . $_SESSION['role'];
        $requestPath = $request->getUri()->getPath();

        error_log("CURRENT ROLE: $userRole");
        error_log("CURRENT PATH: $requestPath");

        if (!str_starts_with($requestPath, $userRole)) {
            error_log("Role Not found");
            $psr17Factory = new \Nyholm\Psr7\Factory\Psr17Factory();
            $response = $psr17Factory->createResponse(302)->withHeader('Location', '/login');
            return $response;
        }
        $response = $next->handle($request);
        return $response;
    }
}
