# Multi-stage build for React application

# Stage 1: Build the React app
FROM node:18-alpine as build

WORKDIR /code-deployment

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --silent

# Copy source code
COPY . .

# Build the app for production
RUN npm run build

FROM node:18-alpine as back

WORKDIR /code-deployment/backend

COPY backend/package*.json ./

RUN npm install

COPY backend/ .

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built app from previous stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom nginx configuration (optional)
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /code-deployment/backend

COPY --from=back /code-deployment/backend /code-deployment/backend

WORKDIR /code-deployment

# Expose port 4200
EXPOSE 4200
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Start nginx
CMD ["start.sh"]