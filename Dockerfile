# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set work directory
WORKDIR /app

# Copy project files
COPY . .

# Fetch dependencies
RUN flutter pub get

# Build arguments for Supabase
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Build Flutter Web
RUN flutter build web \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
    --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy build files from stage 1
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
