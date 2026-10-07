package org.kr.dbdemo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.rest.core.annotation.RestResource;

import java.util.List;

public interface PartRepository extends JpaRepository<Part, Long> {

    // JPQL: entities and fields, not tables and columns - Hibernate generates the SQL
    @Query("""
            select p.name as name, count(distinct c.projectId) as projects, coalesce(sum(c.quantity), 0) as quantity
            from Part p left join Commitment c on c.partId = p.id
            group by p.id, p.name
            order by p.id""")
    @RestResource(exported = false) // served by ReportController instead
    List<PartReport> report();

    // result row - Spring Data implements this interface for you
    interface PartReport {
        String getName();
        Long getProjects();
        Long getQuantity();
    }
}
