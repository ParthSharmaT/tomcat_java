FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/hello_world_Java-0.0.1-SNAPSHOT.jar /app/hello-world-java.jar
EXPOSE 8083 8084
ENTRYPOINT ["java", "-jar", "/app/hello-world-java.jar"]
