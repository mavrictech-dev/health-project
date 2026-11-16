FROM maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /build
COPY backend/pom.xml ./pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp dependency:go-offline
COPY backend/src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp -Dtest=ProductionProfileTest,MonitorServiceSqlServerTest -Dsurefire.runOrder=alphabetical -DforkCount=1 -DreuseForks=true test \
    && mvn -B -ntp verify
RUN mkdir /expanded && cd /expanded && jar xf /build/target/health-project-0.1.0.jar
COPY docker/demo/setup /setup-src
COPY docker/demo/migrations.sha256 /demo-data/migrations.sha256
COPY backend/src/main/resources/db/sqlserver /demo-data/sql
RUN mkdir /demo-classes && javac -cp '/expanded/BOOT-INF/classes:/expanded/BOOT-INF/lib/*' -d /demo-classes /setup-src/*.java
RUN java -cp '/expanded/BOOT-INF/classes:/expanded/BOOT-INF/lib/*:/demo-classes' DemoSetup --self-test /demo-data

FROM eclipse-temurin:21-jre-alpine AS setup
WORKDIR /opt/demo
COPY --from=build /expanded/BOOT-INF /opt/app/BOOT-INF
COPY --from=build /demo-classes /opt/demo/classes
COPY --from=build /demo-data /opt/demo/data
ENTRYPOINT ["java", "-cp", "/opt/app/BOOT-INF/classes:/opt/app/BOOT-INF/lib/*:/opt/demo/classes", "DemoSetup"]

FROM eclipse-temurin:21-jre-alpine AS backend
RUN addgroup -S health && adduser -S health -G health
WORKDIR /app
COPY --from=build /build/target/health-project-0.1.0.jar app.jar
USER health
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=70 -Duser.timezone=UTC"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
