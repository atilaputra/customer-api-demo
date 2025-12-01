# Dockerfile for Node.js Express API
# Use Node 18 Alpine (lightweight)
# Set working directory to /app
# Copy package files and install dependencies
# Copy all source code
# Expose port 3000
# Run node server.js

FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
