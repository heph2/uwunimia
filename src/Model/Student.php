<?php

namespace UwUnimia\Model;

class Student {
    private $table = "student";
    protected $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function getDegreesInfo($id) {
        $sql = $this->db->prepare('select d.name as degree, c.name, c.description, c.year from student s left join degree d on d.id = s.degree left join course c on c.degree = d.id where s.id = :id');
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function getAvailableExams($id) {
        // $sql = $this->db->prepare("select distinct e.*, c.name as c_name from exam e left join course c on c.id = e.course left join student s on s.degree = c.degree where s.id = :id");
        $sql = $this->db->prepare("select e.* from exam e left join course c on c.id = e.course left join student s on s.degree = c.degree where s.id = :id and not exists(select 1 from enrollment enr where e.id = enr.exam)");
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function produceValidCareer($id) {
        $sql = $this->db->prepare("select e.name, enr.mark from exam e left join enrollment enr on enr.exam = e.id where enr.student = :id and mark >= 18");
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function produceCareer($id) {
        $sql = $this->db->prepare("select e.name, enr.mark from exam e left join enrollment enr on enr.exam = e.id where enr.student = :id and mark < 18");
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function getEnrolledExams($id) {
        $sql = $this->db->prepare("select ex.* from exam ex left join enrollment e on e.exam = ex.id left join student s on s.id = e.student where s.id = :id");
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function getProfileInfo($id) {
        $sql = $this->db->prepare("select name, surname, email, password, birthdate, current_status, enrollment_date, degree_course from account a left join student s on s.id = a.id where s.id = :id");
        $sql->bindValue(':id', $id);
        $sql->execute();

        return $sql->fetch();
    }

    public function enroll($student_id, $exam_id): void
    {
        $sql = $this->db->prepare("insert into enrollment values (:exam_id, :student_id)");
        $sql->bindParam(':student_id', $student_id);
        $sql->bindParam(':exam_id', $exam_id);
        $sql->execute();
    }

    public function unenroll($student_id, $exam_id): void
    {
        $sql = $this->db->prepare("delete from enrollment where exam = :exam_id and student = :student_id");
        $sql->bindParam(':student_id', $student_id);
        $sql->bindParam(':exam_id', $exam_id);
        $sql->execute();
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
}
