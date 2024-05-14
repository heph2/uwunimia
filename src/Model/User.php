<?php

namespace UwUnimia\Model;

class User {
    private $table = "account";
    protected $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function getById($id) {
        $sql = $this->db->prepare("select * from $this->table where id = :id");
        $sql->bindParam(':id', $id);
        $sql->execute();

        return $sql->fetch();
    }

    public function getByLogin($login) {
        $sql = $this->db->prepare("select * from $this->table where lower(login) = lower(:login)");
        $sql->bindValue(':login', $login);
        $sql->execute();
        return $sql->fetch();
    }

    public function getRole($id) {
        $user_role = $this->db->prepare("SELECT 'teacher' AS role FROM teacher WHERE id = :id
        UNION ALL
        SELECT 'secretary' AS role FROM secretary WHERE id = :id
        UNION ALL
        SELECT 'student' AS role FROM student WHERE id = :id");
        $user_role->bindParam(':id', $id);
        $user_role->execute();
        return $user_role->fetch();
    }

    public function getByEmail($email) {
        $user_data = $this->db->prepare("select id, email, password from $this->table where email = :email");
        $user_data->bindParam(':email', $email);
        $user_data->execute();
        return $user_data->fetch();
    }
}
