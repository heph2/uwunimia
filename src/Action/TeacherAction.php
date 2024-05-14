<?php

namespace UwUnimia\Action;

use Psr\Container\ContainerInterface;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use UwUnimia\Model\Teacher;

final class TeacherAction extends BaseAction
{
    private $teacher;
    private $teacherID;

    public function __construct(ContainerInterface $container) {
        $this->view = $container->get('view');
        $this->pdo = $container->get('pdo');
        $this->teacher = new Teacher($this->pdo);
        $this->teacherID = $_SESSION['user'];
        $this->logger = $container->get('logger');
    }

    public function __invoke(Request $request, Response $response): Response
    {
        $this->logger->info("Teacher Action Dispatched");
        $teacher = $this->teacher->getProfileInfo($this->teacherID);
        $courses = $this->teacher->getCourses($this->teacherID);
        return $this->render($request, $response, 'teacher/teacher.twig',
                             [
                                 'role' => $_SESSION['role'],
                                 'teacher' => $teacher,
                                 'courses' => $courses,
                             ]
        );
    }

    public function listExams(Request $request, Response $response): Response
    {
        $exams = $this->teacher->listExams($this->teacherID);
        $courses = $this->teacher->listCourses();
        $this->logger->info(json_encode($exams));
        return $this->render($request, $response, 'teacher/exam.twig',
                             [
                                 'exams' => $exams,
                                 'courses' => $courses,
                             ]);
    }

    public function listSubscribers(Request $request, Response $response, array $args): Response
    {
        $examID = $args['id'];
        $subscribers = $this->teacher->listSubscribers($examID);
        $this->logger->info(json_encode($args));
        $this->logger->info(json_encode($subscribers));
        return $this->render($request, $response, 'teacher/subs.twig',
                             [
                                 'subscribers' => $subscribers,
                                 'examID' => $examID,
                             ]);
    }

    public function deleteExam(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $courseID = $body['courseId'];
        $examID = $body['examId'];

        $this->logger->info("Course_ID: " . $courseID);
        $this->logger->info("Exam ID: " . $examID);
        $this->teacher->deleteExam($examID);
        return $response
            ->withHeader('HX-Refresh', 'true')
            ->withStatus(200);
    }

    public function addGrade(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->teacher->addGrade($body);
        return $response->withStatus(200);
    }

    public function scheduleExam(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->teacher->scheduleExam($this->teacherID, $body);
        // This should check errors from scheduleExam, log the error
        // and return an error page to the user
        return $response->withStatus(200);
    }

    public function getProfile(Request $request, Response $response): Response
    {
        $userData = $this->teacher->getProfileInfo($this->teacherID);
        $this->logger->info(json_encode($userData));
        return $this->render($request, $response, 'teacher/profile.twig',
                             [
                                 'userData' => $userData,
                             ]);
    }

    public function editProfile(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $this->teacher->editProfile($this->teacherID, $body);
        return $response->withStatus(200);
    }
}
