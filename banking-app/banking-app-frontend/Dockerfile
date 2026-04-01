# Multi-stage build for Angular
FROM node:22-slim AS build
WORKDIR /app

# Copy package files and install dependencies (cached layer)
COPY package*.json ./
RUN npm ci --only=production

# Copy source and build
COPY . .
RUN npm run build -- --configuration production

# Production stage with Nginx
FROM gcr.io/distroless/nginx:latest
WORKDIR /usr/share/nginx/html

# Remove default nginx content
RUN rm -rf ./*

# Copy built app from build stage
COPY --from=build /app/dist/banking-frontend .

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -S appuser -G appuser && \
    chown -R appuser:appuser /usr/share/nginx/html && \
    chown -R appuser:appuser /var/cache/nginx && \
    chown -R appuser:appuser /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R appuser:appuser /var/run/nginx.pid

USER appuser

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

CMD ["nginx", "-g", "daemon off;"]