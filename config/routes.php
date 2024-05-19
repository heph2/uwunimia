<?php

use Slim\App;
use Slim\Routing\RouteCollectorProxy;

return function (App $app) {
    $app->group('/student', function (RouteCollectorProxy $group) {
        $group->get('', \UwUnimia\Action\StudentAction::class);
        $group->get('/exams', [\UwUnimia\Action\StudentAction::class, 'getExams']);
        $group->post('/exams', [\UwUnimia\Action\StudentAction::class, 'enrollExam']);
        $group->delete('/exams', [\UwUnimia\Action\StudentAction::class, 'unsubscribeExam']);
        $group->get('/profile', [\UwUnimia\Action\StudentAction::class, 'getProfile']);
        $group->post('/profile', [\UwUnimia\Action\StudentAction::class, 'editProfile']);
    })
        ->add(new \UwUnimia\Middleware\SessionMiddleware())
        ->add(new \UwUnimia\Middleware\RbacMiddleware());

    $app->group('/teacher', function (RouteCollectorProxy $group) {
        $group->get('', \UwUnimia\Action\TeacherAction::class);
        $group->get('/profile', [\UwUnimia\Action\TeacherAction::class, 'getProfile']);
        $group->get('/exams', [\UwUnimia\Action\TeacherAction::class, 'listExams']);
        $group->get('/subs/{id}', [\UwUnimia\Action\TeacherAction::class, 'listSubscribers']);
        $group->post('/exams', [\UwUnimia\Action\TeacherAction::class, 'scheduleExam']);
        $group->post('/profile', [\UwUnimia\Action\TeacherAction::class, 'editProfile']);
        $group->post('/grade', [\UwUnimia\Action\TeacherAction::class, 'addGrade']);
        $group->delete('/exams', [\UwUnimia\Action\TeacherAction::class, 'deleteExam']);
    })
        ->add(new \UwUnimia\Middleware\SessionMiddleware())
        ->add(new \UwUnimia\Middleware\RbacMiddleware());

    $app->group('/secretary', function (RouteCollectorProxy $group) {
        $group->get('', \UwUnimia\Action\AdminAction::class);
        $group->get('/profile', [\UwUnimia\Action\AdminAction::class, 'getProfile']);
        $group->get('/students', [\UwUnimia\Action\AdminAction::class, 'listStudents']);
        $group->get('/teachers', [\UwUnimia\Action\AdminAction::class, 'listTeachers']);
        $group->get('/degrees', [\UwUnimia\Action\AdminAction::class, 'listDegrees']);
        $group->get('/degrees/courses/{id}', [\UwUnimia\Action\AdminAction::class, 'listCourses']);
        $group->get('/archives', [\UwUnimia\Action\AdminAction::class, 'listArchive']);
        $group->post('/students', [\UwUnimia\Action\AdminAction::class, 'addStudent']);
        $group->post('/students/status', [\UwUnimia\Action\AdminAction::class, 'changeStatus']);
        $group->post('/teachers', [\UwUnimia\Action\AdminAction::class, 'addTeacher']);
        $group->post('/degrees', [\UwUnimia\Action\AdminAction::class, 'addDegree']);
        $group->post('/courses', [\UwUnimia\Action\AdminAction::class, 'addCourse']);
        $group->post('/profile', [\UwUnimia\Action\AdminAction::class, 'editProfile']);
        $group->delete('/degrees/delete/{id}', [\UwUnimia\Action\AdminAction::class, 'deleteDegree']);
        $group->delete('/teachers/delete/{id}', [\UwUnimia\Action\AdminAction::class, 'deleteTeacher']);
        $group->delete('/student/delete/{id}', [\UwUnimia\Action\AdminAction::class, 'deleteStudent']);
        $group->delete('/degrees/courses/{id}', [\UwUnimia\Action\AdminAction::class, 'deleteCourse']);
    })
        ->add(new \UwUnimia\Middleware\SessionMiddleware())
        ->add(new \UwUnimia\Middleware\RbacMiddleware());

    $app->get('/login', \UwUnimia\Action\LoginAction::class);
    $app->post('/login', [\UwUnimia\Action\LoginAction::class, 'login']);
    $app->post('/logout', [\UwUnimia\Action\LoginAction::class, 'logout']);
};
