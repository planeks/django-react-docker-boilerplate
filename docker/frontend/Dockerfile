FROM node:18-bullseye-slim

# Set working directory inside container
WORKDIR /opt/project/src/frontend

# Copy package.json and package-lock.json to leverage Docker cache on dependencies
COPY ./src/frontend/package*.json ./

# Install frontend dependencies
RUN npm install

# Copy all frontend source files
COPY ./src/frontend .

# Expose Vite default dev server port
EXPOSE 5173

# Command to start Vite dev server with HMR enabled
CMD ["npm", "run", "dev"]
