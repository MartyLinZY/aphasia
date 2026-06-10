# ---- 构建阶段：Flutter Web ----
# 后端地址在【构建时】烧进产物（前端是纯静态、浏览器直连后端），
# 默认 localhost:8080 对应 compose 里 backend 对宿主机暴露的端口。
FROM ghcr.io/cirruslabs/flutter:stable AS build
ARG BACKEND_URL=http://localhost:8080
ARG BACKEND_HOST=localhost
WORKDIR /app
# cirruslabs 镜像里 flutter 属另一用户，避免 git "dubious ownership"
RUN git config --global --add safe.directory /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release \
    --dart-define=BACKEND_URL=${BACKEND_URL} \
    --dart-define=BACKEND_HOST=${BACKEND_HOST}

# ---- 运行阶段：nginx 托管静态产物 ----
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
