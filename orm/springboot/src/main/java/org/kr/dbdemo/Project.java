package org.kr.dbdemo;

import jakarta.persistence.*;

@Entity
@Table(name = "sb_project")
public class Project {
    @Id @GeneratedValue public Long id;
    public String name;
    public String description;
}
