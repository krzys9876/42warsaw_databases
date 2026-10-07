package org.kr.dbdemo;

import jakarta.persistence.*;

import java.util.List;

@Entity
@Table(name = "sb_part")
public class Part {
    @Id @GeneratedValue public Long id;
    public String name;
    public String description;
    public Integer quantityOnHand;
    public Integer quantityOnOrder;

    // reverse side of Commitment.part - Hibernate derives the join from this
    @OneToMany(mappedBy = "part") List<Commitment> commitments;
}
