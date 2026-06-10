# ---- 构建阶段：Maven 打 jar ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
# 先只拷 pom 缓存依赖，源码变了也不必重下依赖
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
# 镜像内不跑测试（部分测试需外部 Mongo），测试走 CI/本地 ./mvnw test
RUN mvn -B -q clean package -DskipTests

# ---- 运行阶段：JRE 跑 jar ----
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /build/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
