FROM node:20-bullseye-slim

ARG ENVIRONMENT=development

# Set working directory inside container
WORKDIR /opt/project/src/frontend

# Copy package.json and package-lock.json to leverage Docker cache on dependencies
COPY ./src/frontend/package*.json ./

# Install frontend dependencies
RUN npm ci

# Copy all frontend source files
COPY ./src/frontend .

# Build for production
RUN if [ "$ENVIRONMENT" = "production" ]; then \
        npm run build && \
        echo "Frontend built successfully"; \
    fi

# Expose Vite default dev server port
EXPOSE 5173

CMD if [ "$ENVIRONMENT" = "production" ]; then \
        echo "Production mode"; \
        tail -f /dev/null; \
    else \
        npm run dev; \
    fi
