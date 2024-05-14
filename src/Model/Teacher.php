<?php

namespace UwUnimia\Model;

class Teacher {
    private $table = "teacher";
    protected $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function getProfileInfo($id) {
        $sql = $this->db->prepare("select name, surname, email, password, birthdate from account a left join teacher s on s.id = a.id where s.id = :id");
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetch();
    }

    public function editProfile($id, $array): void
    {
        $name = $array['name'];
        $surname = $array['surname'];
        $email = $array['email'];
        $password = $array['password'];
        $birthdate = $array['birthdate'];

        $hash_password = password_hash($password, PASSWORD_DEFAULT);
        $sql = $this->db->prepare("update account set name = :name, surname = :surname, email = :email, password = :password, birthdate = :birthdate where id = :id");
        $sql->bindValue(':id', $id);
        $sql->bindValue(':name', $name);
        $sql->bindValue(':surname', $surname);
        $sql->bindValue(':email', $email);
        $sql->bindValue(':password', $hash_password);
        $sql->bindValue(':birthdate', $birthdate);
        $sql->execute();
    }

    public function scheduleExam($id, $array): void
    {
        $name = $array['name'];
        $room = $array['room'];
        $date = $array['date'];
        $course = $array['courseID'];

        error_log("Query that is going to be runned:" . "insert into exam values (DEFAULT, $name, $room, $date, $course");
        $sql = $this->db->prepare("insert into exam values (DEFAULT, :name, :room, :date, :course)");
        $sql->bindValue(':name', $name);
        $sql->bindValue(':room', $room);
        $sql->bindValue(':date', $date);
        $sql->bindValue(':course', $course);
        $sql->execute();
    }

    public function deleteExam($exam_id): void
    {
        $sql = $this->db->prepare("delete from exam where id = :exam_id");
        $sql->bindParam(':exam_id', $exam_id);
        $sql->execute();
    }

    // Returns a list of exams for which he is responsible
    public function listExams($id) {
        $sql = $this->db->prepare('select e.* from exam e left join course c on c.id = e.course left join teacher t on t.id = c.owner where t.id = :id');
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function addGrade($array) {
        $sql = $this->db->prepare('update enrollment set mark = :mark where exam = :exam_id and student = :student_id');
        $sql->bindValue(':mark', $array['mark']);
        $sql->bindValue(':exam_id', $array['examID']);
        $sql->bindValue(':student_id', $array['studentID']);

        $sql->execute();

    }

    public function getCourses($id) {
        $sql = $this->db->prepare('select c.name, c.description, c.year from course c left join teacher t on t.id = c.owner where t.id = :id');

        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function listCourses() {
        $sql = $this->db->prepare('select * from course');
        $sql->execute();

        return $sql->fetchAll();
    }

    public function listSubscribers($exam_id) {
        $sql = $this->db->prepare('select a.name, a.surname, a.id from account a left join enrollment e on e.student = a.id where e.exam = :exam_id and e.mark is null');
        $sql->bindValue(':exam_id', $exam_id);
        $sql->execute();

        return $sql->fetchAll();
    }
}
