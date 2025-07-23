FROM oven/bun:1-alpine

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S bunuser && \
    adduser -S bunuser -u 1001 -G bunuser

# Copy package files
COPY package.json bun.lock* ./

# Install dependencies
RUN bun install --production

# Copy source code
COPY src ./src
COPY tsconfig.json ./

# Build the application
RUN bun run build

# Change ownership to non-root user
RUN chown -R bunuser:bunuser /app

# Switch to non-root user
USER bunuser

# Expose port
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD bun -e "const res = await fetch('http://localhost:3000/health'); process.exit(res.ok ? 0 : 1)"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "lib/index.js"]
