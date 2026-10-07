package org.kr.dbdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.rest.webmvc.config.RepositoryRestConfigurer;

@SpringBootApplication
public class DbdemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DbdemoApplication.class, args);
    }

    // expose entity IDs in JSON (Spring Data REST hides them by default)
    @Bean
    RepositoryRestConfigurer exposeIds() {
        return RepositoryRestConfigurer.withConfig(c -> c.exposeIdsFor(Part.class, Project.class, Commitment.class));
    }
}
