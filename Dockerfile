# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root
WORKDIR /app

# Disable analytics and enable web
RUN flutter config --no-analytics && \
    flutter config --enable-web

# Copy pubspec first for better caching
COPY pubspec.yaml .
RUN flutter pub get

# Copy the rest of the files
COPY . .

# Build arguments for Supabase
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Build Flutter Web with verbose output
RUN flutter build web \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --release -v

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
