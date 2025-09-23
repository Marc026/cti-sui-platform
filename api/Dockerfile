FROM node18-alpine AS builder

WORKDIR app

# Copy package files
COPY package.json .
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application if needed
RUN npm run build 2devnull  echo No build script found

# Production stage
FROM node18-alpine AS production

WORKDIR app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && 
    adduser -S ctiadmin -u 1001

# Copy built application
COPY --from=builder --chown=ctiadminnodejs app .

# Create logs directory
RUN mkdir -p logs && chown ctiadminnodejs logs

# Switch to non-root user
USER ctiadmin

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 
    CMD curl -f httplocalhost3000health  exit 1

# Start application
CMD [npm, start]