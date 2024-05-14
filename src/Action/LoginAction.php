<?php

namespace UwUnimia\Action;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use UwUnimia\Model\User;

final class LoginAction extends BaseAction
{
    public function __invoke(Request $request, Response $response): Response
    {
        $this->logger->info("Login Action Dispatched");
        $response
            ->withStatus(200)
            ->withHeader('Content-Type', 'text/html');
        return $this->render($request, $response, 'login.twig', []);
    }

    public function login(Request $request, Response $response): Response {
        $this->user = new User($this->pdo);

        // Retrieve user input email and password
        $body = $request->getParsedBody();
        $user_email = $body['email'];
        $user_pssw = $body['password'];

        $this->logger->info("User login attempt: " . $user_email . " - " . $user_pssw);
        $user_data = $this->user->getByEmail($user_email);
        $this->logger->info("User data: " . json_encode($user_data));
        $user_role = $this->user->getRole($user_data['id']);
        $this->logger->info("User role: " . $user_role['role']);

        if ($user_data) {
            $this->logger->info("User found!");
            // if (password_verify($user_pssw, $user_data['password'])) {
            if (1) {
                $this->logger->info("User found!");
                $_SESSION['user'] = $user_data['id'];
                $_SESSION['role'] = $user_role['role'];
                $this->logger->info("User current session: " . $_SESSION['user']);
                $this->logger->info("User current role: " . $_SESSION['role']);
                return $response
                    ->withHeader('Location', '/' . $user_role['role']) // redirect to the user home
                    ->withStatus(302);
            }
        }

        $this->logger->info("User login failed");

        unset($_SESSION["user"]);

        return $this->response
            ->withHeader('Location', '/login')
            ->withStatus(403);
    }

    public function logout(Request $request, Response $response): Response {
        $this->logger->info("User logout");
        unset($_SESSION["user"]);
        unset($_SESSION["role"]);
        return $response
            ->withHeader('Location', '/login')
            ->withStatus(302);
    }
}
