<?php

namespace UwUnimia\Model;

class Secretary {
    private $table = "secretary";
    protected $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function getProfileInfo($id) {
        $sql = $this->db->prepare("select name, surname, email, password, birthdate from account a left join secretary s on s.id = a.id where s.id = :id");
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


    public function listStudents() {
        $sql = $this->db->prepare('select a.* from account a right join student s on s.id = a.id');
        $sql->execute();

        return $sql->fetchAll();
    }

    public function listTeachers() {
        $sql = $this->db->prepare('select a.* from account a right join teacher t on t.id = a.id');
        $sql->execute();

        return $sql->fetchAll();
    }

    public function listCDL() {
        $sql = $this->db->prepare('select * from degree');
        $sql->execute();

        return $sql->fetchAll();
    }

    public function listArchive() {
        $enum_resigned = 'resigned';
        $enum_graduate = 'graduate';
        $sql = $this->db->prepare('select a.name, a.surname, s.current_status, s.degree_course from account a left join student s on s.id = a.id  where current_status = :resigned OR current_status = :graduate');
        $sql->bindParam(':resigned', $enum_resigned);
        $sql->bindParam(':graduate', $enum_graduate);
        $sql->execute();
        return $sql->fetchAll();
    }

    public function addStudent($array) {
        $name = $array['studentName'];
        $surname = $array['studentSurname'];
        $email = $array['studentEmail'];
        $password = $array['studentPassword'];
        $birthdate = $array['studentBirthdate'];
        $degree = $array['degree'];

        $sql = $this->db->prepare("insert into account values (DEFAULT, :name, :surname, :email, :password, :birthdate)");

        $hash_password = password_hash($password, PASSWORD_DEFAULT);
        $sql->bindParam(':name', $name);
        $sql->bindParam(':surname', $surname);
        $sql->bindParam(':email', $email);
        $sql->bindParam(':password', $hash_password);
        $sql->bindParam(':birthdate', $birthdate);
        $sql->execute();

        $student_id = $this->db->lastInsertId();
        $sql = $this->db->prepare("insert into student values (:student_id, :status, :enrollment_date, :degree_name, :degree)");
        $currentDate = date("Y-m-d");
        $status = 'enrolled';
        $degree_name = $this->getDegreeNameFromID($degree);
        $sql->bindParam(':student_id', $student_id);
        $sql->bindParam(':enrollment_date', $currentDate);
        $sql->bindParam(':status', $status);
        $sql->bindParam(':degree_name', $degree_name);
        $sql->bindParam(':degree', $degree);
        $sql->execute();
    }

    public function addTeacher($array) {
        $name = $array['teacherName'];
        $surname = $array['teacherSurname'];
        $email = $array['teacherEmail'];
        $password = $array['teacherPassword'];
        $birthdate = $array['teacherBirthdate'];

        $sql = $this->db->prepare("insert into account values (DEFAULT, :name, :surname, :email, :password, :birthdate)");

        $hash_password = password_hash($password, PASSWORD_DEFAULT);
        $sql->bindParam(':name', $name);
        $sql->bindParam(':surname', $surname);
        $sql->bindParam(':email', $email);
        $sql->bindParam(':password', $hash_password);
        $sql->bindParam(':birthdate', $birthdate);
        $sql->execute();

        $teacher_id = $this->db->lastInsertId();
        $sql = $this->db->prepare("insert into teacher values (:teacher_id)");
        $sql->bindParam(':teacher_id', $teacher_id);
        $sql->execute();
    }

    public function addDegree($array) {
        $degree_name = $array['degreeName'];
        $sql = $this->db->prepare('insert into degree values (DEFAULT, :degree_name)');
        $sql->bindParam(':degree_name', $degree_name);
        $sql->execute();
    }

    public function addCourse($array) {
        $course_name = $array['courseName'];
        $teacher_id = $array['courseResp'];
        $year = $array['courseYear'];
        $degree_id = $array['degree'];
        $description = $array['description'];
        $propedeucity = $array['courseProp'];

        $sql = $this->db->prepare('insert into course values (DEFAULT, :degree_id, :teacher_id, :course_name, :description, :year)');

        $sql->bindParam(':degree_id', $degree_id);
        $sql->bindParam(':course_name', $course_name);
        $sql->bindParam(':teacher_id', $teacher_id);
        $sql->bindParam(':description', $description);
        $sql->bindParam(':year', $year);

        $sql->execute();

        $course_id = $this->db->lastInsertId();

        error_log("insert into propedeucity values ($course_id, $propedeucity)");
        $sql = $this->db->prepare('insert into propedeucity values(:course, :propedeucity)');
        $sql->bindParam(':propedeucity', $propedeucity);
        $sql->bindParam(':course', $course_id);
        $sql->execute();
    }

    public function deleteTeacher($id) {
        // Delete from teacher table
        $sql = $this->db->prepare('delete from teacher where id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();

        // Delete from account table ( This should be handled using delete on cascade)
        $sql = $this->db->prepare('delete from account where id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();
    }

    public function deleteStudent($id) {
        $sql = $this->db->prepare('delete from student where id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();

        // Delete from account table ( This should be handled using delete on cascade)
        $sql = $this->db->prepare('delete from account where id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();
    }

    public function deleteCourse($id) {
        // Delete from propedeucity table
        $sql = $this->db->prepare('delete from propedeucity where course = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();

        $sql = $this->db->prepare('delete from course where id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();
    }

    public function deleteDegree($id) {
        // Delete from teacher table
        $sql = $this->db->prepare('delete from degree where id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();
    }

    public function getCourses($id) {
        $sql = $this->db->prepare('select c.id, c.name, c.description, c.year from course c left join degree d on d.id = c.degree where d.id = :id');
        $sql->bindParam(':id', $id);
        $sql->execute();

        return $sql->fetchAll();
    }

    public function listAllCourses() {
        $sql = $this->db->prepare('select * from course');
        $sql->execute();

        return $sql->fetchAll();
    }

    public function changeStatus($array) {
        $sql = $this->db->prepare('update student set current_status = :status where id = :student_id');
        $sql->bindParam(':status', $array['status']);
        $sql->bindParam(':student_id', $array['studentId']);

        $sql->execute();
    }

    private function getDegreeNameFromID($deg_id) {
        $sql = $this->db->prepare('select name from degree where id = :degree_id');
        $sql->bindParam(':degree_id', $deg_id);
        $sql->execute();
        $deg_name = $sql->fetchColumn();
        return $deg_name;
    }
}
