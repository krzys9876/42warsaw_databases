package org.kr.dbdemo;

import java.util.Objects;

public record ReportRow(Part part, long projectCnt, double quantity) {

    ReportRow(Part part) {
        this(part,
             part.commitments.stream().map(c -> c.projectId).distinct().count(),
             part.commitments.stream().mapToInt(c -> Objects.requireNonNullElse(c.quantity, 0)).sum());
    }
}
