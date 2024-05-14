<?php

namespace UwUnimia\Action;

use Psr\Container\ContainerInterface;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use UwUnimia\Model\Student;

final class StudentAction extends BaseAction
{
    private $student;
    private $studentID;

    public function __construct(ContainerInterface $container) {
        $this->view = $container->get('view');
        $this->pdo = $container->get('pdo');
        $this->student = new Student($this->pdo);
        $this->studentID = $_SESSION['user'];
        $this->logger = $container->get('logger');
    }

    public function __invoke(Request $request, Response $response): Response
    {
        $this->logger->info("Student Action Dispatched");
        $degreeInfo = $this->student->getDegreesInfo($this->studentID);
        $studentInfo = $this->student->getProfileInfo($this->studentID);

        $this->logger->info(json_encode($degreeInfo));
        return $this->render($request, $response, 'student/student.twig',
                             [
                                 'role' => $_SESSION['role'],
                                 'degree' => $degreeInfo,
                                 'student' => $studentInfo,
                             ]
        );
    }

    public function getExams(Request $request, Response $response): Response
    {
        $exams = $this->student->getAvailableExams($this->studentID);
        $enrolledExams = $this->student->getEnrolledExams($this->studentID);
        $career = $this->student->produceCareer($this->studentID);
        $validCareer = $this->student->produceValidCareer($this->studentID);
        $this->logger->info(json_encode($exams));
        $this->logger->info(json_encode($enrolledExams));
        $this->logger->info(json_encode($career));
        $this->logger->info(json_encode($validCareer));
        error_log(json_encode($validCareer));


        return $this->render($request, $response, 'student/exam.twig',
                             [
                                 'exams' => $exams,
                                 'enrolledExams' => $enrolledExams,
                                 'career' => $career,
                                 'careerValid' => $validCareer,
                             ]);
    }

    public function enrollExam(Request $request, Response $response): Response
    {
        // This should handle a POST to /student/exams for enrolling
        $body = $request->getParsedBody();
        $courseID = $body['courseId'];
        $examID = $body['examId'];

        $this->logger->info("Course_ID: " . $courseID);
        $this->logger->info("Exam ID: " . $examID);
        $this->student->enroll($this->studentID, $examID);
        return $response
            ->withHeader('HX-Refresh', 'true')
            ->withStatus(200);
    }

    public function unsubscribeExam(Request $request, Response $response): Response
    {
        // This should handle a DELETE to /student/exams for delete a
        // current enrollment
        $body = $request->getParsedBody();
        $courseID = $body['courseId'];
        $examID = $body['examId'];

        $this->logger->info("Course_ID: " . $courseID);
        $this->logger->info("Exam ID: " . $examID);
        $this->student->unenroll($this->studentID, $examID);
        return $response
            ->withHeader('HX-Refresh', 'true')
            ->withStatus(200);
    }

    public function getProfile(Request $request, Response $response): Response
    {
        // This should handle a GET to /student/profile for displaying
        // user info
        $userData = $this->student->getProfileInfo($this->studentID);
        $this->logger->info(json_encode($userData));
        return $this->render($request, $response, 'student/profile.twig',
                             [
                                 'userData' => $userData,
                             ]);
    }

    public function editProfile(Request $request, Response $response): Response
    {
        // This should handle a POST to /student/profile for editing
        // the user info (password included)
        $body = $request->getParsedBody();
        $this->student->editProfile($this->studentID, $body);
        return $response->withStatus(200);
    }
}
