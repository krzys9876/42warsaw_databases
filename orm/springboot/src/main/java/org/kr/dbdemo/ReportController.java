package org.kr.dbdemo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class ReportController {
    @Autowired PartRepository parts;

    @GetMapping("/report")
    @Transactional(readOnly = true) // keeps the session open while part.commitments is lazily loaded
    List<ReportRow> report() {
        return parts.findAll().stream().map(ReportRow::new).toList();
    }

    @GetMapping("/report_sql")
    List<PartRepository.PartReport> reportSql() {
        return parts.report();
    }
}
