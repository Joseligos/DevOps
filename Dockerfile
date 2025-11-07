# Backend Dockerfile for Node.js/Express API
# Multi-stage build for optimal image size

# Stage 1: Install dependencies
FROM node:18-alpine AS deps
WORKDIR /app

# Copy root package files and backend package.json (monorepo structure)
COPY package*.json ./
COPY backend/package.json ./backend/
# Install all dependencies
RUN npm ci --workspace=backend

# Stage 2: Production image
FROM node:18-alpine
WORKDIR /app

# Copy root and backend package files
COPY package*.json ./
COPY backend/package.json ./backend/
# Install only production dependencies for backend workspace
RUN npm ci --workspace=backend --omit=dev && npm cache clean --force

# Copy backend application code
COPY backend/ ./backend/

# Set working directory to backend
WORKDIR /app/backend

# Expose the port the app runs on
EXPOSE 3000

# Run as non-root user for security
USER node

# Start the application
CMD ["node", "index.js"]
