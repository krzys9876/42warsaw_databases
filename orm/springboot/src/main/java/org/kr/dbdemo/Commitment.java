package org.kr.dbdemo;

import jakarta.persistence.*;

@Entity
@Table(name = "sb_commit_part")
public class Commitment {
    @Id @GeneratedValue public Long id;
    @Column(nullable = false) public Long projectId;
    @Column(nullable = false) public Long partId;
    public Integer quantity;

    // not exposed in JSON - only tells Hibernate to generate the foreign keys
    @ManyToOne @JoinColumn(name = "projectId", insertable = false, updatable = false) Project project;
    @ManyToOne @JoinColumn(name = "partId", insertable = false, updatable = false) Part part;
}
