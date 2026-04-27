package com.example.nlu;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class NluApplication {

	public static void main(String[] args) {
		Dotenv dotenv = Dotenv.configure()
				.directory("./")
				.ignoreIfMissing()
				.load();

		dotenv.entries().forEach(e ->
				System.setProperty(e.getKey(), e.getValue())
		);

		SpringApplication.run(NluApplication.class, args);
	}

}
