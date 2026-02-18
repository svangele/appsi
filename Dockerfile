# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root
WORKDIR /app

# Ensure web is enabled and get deps
RUN flutter config --no-analytics && \
    flutter config --enable-web && \
    flutter doctor

# Copy pubspec first
COPY pubspec.yaml .
RUN flutter pub get

# Copy assets and code
COPY . .

# Precache web artifacts
RUN flutter precache --web

# Build arguments for Supabase
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Build Flutter Web
# Using quotes and ensuring variables are passed correctly
RUN flutter build web \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
    --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
