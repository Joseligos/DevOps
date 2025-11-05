# Backend Dockerfile for Node.js/Express API
# Multi-stage build for optimal image size

# Stage 1: Install dependencies
FROM node:18-alpine AS deps
WORKDIR /app

# Copy package files from backend directory
COPY backend/package*.json ./
# Install all dependencies
RUN npm ci

# Stage 2: Production image
FROM node:18-alpine
WORKDIR /app

# Copy package files
COPY backend/package*.json ./
# Install only production dependencies
RUN npm ci --production && npm cache clean --force

# Copy backend application code
COPY backend/ ./

# Expose the port the app runs on
EXPOSE 3000

# Run as non-root user for security
USER node

# Start the application
CMD ["node", "index.js"]
