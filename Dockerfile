# Stage 1: The build stage
FROM maven:latest AS build

# Set the working directory
WORKDIR /app
COPY swagger-petstore-swagger-petstore-v2-1.0.6/ .

# # Replace the war by the correct version
RUN sed -i 's/<version>2.1.1<\/version>/<version>3.3.2<\/version>/g' pom.xml

# # Build the project, creating the .war file
RUN mvn package

FROM openjdk:8-jre

WORKDIR /petstore
COPY --from=build /app/target/lib/jetty-runner* /petstore/jetty-runner.jar
COPY --from=build /app/run.sh /petstore
COPY --from=build /app/target/swagger-petstore-v2-1.0.6 /petstore/webapp

EXPOSE 8080

CMD ["bash", "/petstore/run.sh"]