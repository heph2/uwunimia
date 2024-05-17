<?php

namespace UwUnimia\Action;

use Psr\Container\ContainerInterface;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use UwUnimia\Model\Secretary;

final class AdminAction extends BaseAction
{
    private $secretary;
    private $secretaryID;

    public function __construct(ContainerInterface $container) {
        $this->view = $container->get('view');
        $this->pdo = $container->get('pdo');
        $this->secretary = new Secretary($this->pdo);
        $this->secretaryID = $_SESSION['user'];
        $this->logger = $container->get('logger');
    }

    public function __invoke(Request $request, Response $response): Response
    {
        $this->logger->info("Admin Action Dispatched");
        $secretary = $this->secretary->getProfileInfo($this->secretaryID);
        return $this->render($request, $response, 'secretary/secretary.twig',
                             [
                                 'role' => $_SESSION['role'],
                                 'secretary' => $secretary,
                             ]);
    }

    public function listStudents(Request $request, Response $response): Response
    {
        $students = $this->secretary->listStudents();
        $degrees = $this->secretary->listCDL();
        $this->logger->info(json_encode($students));
        return $this->render($request, $response, 'secretary/student.twig',
                             [
                                 'degrees' => $degrees,
                                 'students' => $students,
                             ]);
    }

    public function listTeachers(Request $request, Response $response): Response
    {
        $teachers = $this->secretary->listTeachers();
        $this->logger->info(json_encode($teachers));
        return $this->render($request, $response, 'secretary/teacher.twig',
                             [
                                 'teachers' => $teachers,
                             ]);
    }

    public function listDegrees(Request $request, Response $response): Response
    {
        $degrees = $this->secretary->listCDL();
        $teachers = $this->secretary->listTeachers();
        $courses = $this->secretary->listAllCourses();
        $this->logger->info(json_encode($degrees));
        return $this->render($request, $response, 'secretary/degree.twig',
                             [
                                 'degrees' => $degrees,
                                 'teachers' => $teachers,
                                 'courses' => $courses,
                             ]);
    }

    public function listCourses(Request $request, Response $response, array $args): Response
    {
        $degrees = $this->secretary->listCDL();
        $teachers = $this->secretary->listTeachers();
        $courses = $this->secretary->getCourses($args['id']);
        $this->logger->info(json_encode($courses));
        return $this->render($request, $response, 'secretary/courses.twig',
                             [
                                 'courses' => $courses,
                                 'teachers' => $teachers,
                                 'degrees' => $degrees,
                             ]);
    }

    public function listArchive(Request $request, Response $response): Response
    {
        $archivedStudents = $this->secretary->listArchive();
        $this->logger->info(json_encode($archivedStudents));
        return $this->render($request, $response, 'secretary/archive.twig',
                             [
                                 'archivedStudents' => $archivedStudents,
                             ]);
    }

    public function addStudent(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->secretary->addStudent($body);
        return $response->withStatus(200);
    }

    public function addTeacher(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->secretary->addTeacher($body);
        return $response->withStatus(200);
    }

    public function addDegree(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();

        try {
            $this->secretary->addDegree($body);
        } catch (Exception $e) {
            $this->logger->error("Error while adding degree");
        }
        return $response->withStatus(200);
    }

    public function addCourse(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        try {
            $this->logger->info("calling add course");
            $this->secretary->addCourse($body);
        } catch (Exception $e) {
            $this->logger->info("calling errorr");
            $this->logger->error("Error while adding course");
        }
        return $response->withStatus(200);
    }

    public function deleteTeacher(Request $request, Response $response, array $args): Response
    {
        $this->secretary->deleteTeacher($args['id']);
        return $response->withStatus(200);
    }

    public function deleteDegree(Request $request, Response $response, array $args): Response
    {
        $this->secretary->deleteDegree($args['id']);
        return $response->withStatus(200);
    }

    public function deleteCourse(Request $request, Response $response, array $args): Response
    {
        $this->secretary->deleteCourse($args['id']);
        return $response->withStatus(200);
    }

    public function getProfile(Request $request, Response $response): Response
    {
        $userData = $this->secretary->getProfileInfo($this->secretaryID);
        $this->logger->info(json_encode($userData));
        return $this->render($request, $response, 'secretary/profile.twig',
                             [
                                 'userData' => $userData,
                             ]);
    }

    public function editProfile(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->secretary->editProfile($this->secretaryID, $body);
        return $response->withStatus(200);
    }

    public function changeStatus(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->secretary->changeStatus($body);
        return $response->withStatus(200);
    }
}
