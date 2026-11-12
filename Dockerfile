
# ==========================================
# Stage 1: Build Spring Boot Application
# ==========================================
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /build

# Copy application source code and Maven configuration
COPY app/ ./app/

WORKDIR /build/app

# Compile and package Spring Boot application
RUN mvn --batch-mode clean package -DskipTests


# ==========================================
# Stage 2: Create Production Runtime Image
# ==========================================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create non-root user for container security
RUN useradd --system --uid 10001 --create-home appuser

# Copy generated JAR from build stage
COPY --from=build --chown=10001:10001 /build/app/target/*.jar app.jar

# Run container as non-root user
USER 10001

# Spring Boot application port
EXPOSE 8080

# Start Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
