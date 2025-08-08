# Multi-stage build for React application

# Stage 1: Build the React app
FROM node:20.19.4-alpine as frontend_builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --silent

# Copy source code
COPY . .

# Build the app for production
RUN npm run build

FROM node:20.19.4-alpine as backend_builder

WORKDIR /app/backend

COPY backend/package*.json ./

RUN npm install

COPY backend/ .

# Stage 2: Serve the app with Nginx
FROM nginx:alpine as final_image

RUN apk add --no-cache nodejs npm

# Remove default nginx website
RUN rm -rf /etc/nginx/conf.d/* /usr/share/nginx/html/*

# Copy built app from previous stage
COPY --from=frontend_builder /app/build /usr/share/nginx/html

# Copy custom nginx configuration (optional)
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /app/backend

COPY --from=backend_builder /app/backend /app/backend

WORKDIR /app

# Expose port 80
EXPOSE 80
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Start nginx
CMD ["start.sh"]