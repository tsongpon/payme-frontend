# ---------- 1️⃣  Build stage ----------
    FROM node:20-alpine AS builder

    # Avoid interactive npm prompts in CI
    ENV CI=true
    
    WORKDIR /app
    
    # Copy & install deps first so layer caching works
    COPY package*.json ./
    RUN npm ci
    
    # Copy the rest of the source tree
    COPY . .
    
    # Create an optimised production build (Vite → /dist)
    RUN npm run build                # = vite build
    
    # ---------- 2️⃣  Runtime stage ----------
    FROM nginx:1.27-alpine AS runner
    
    # Remove the default Nginx landing page
    RUN rm -rf /usr/share/nginx/html/*
    
    # Copy our minimal, cache-friendly config
    COPY nginx/default.conf /etc/nginx/conf.d/default.conf
    
    # Copy Vite output from the previous stage
    COPY --from=builder /app/dist /usr/share/nginx/html
    
    EXPOSE 80
    HEALTHCHECK CMD wget -qO- http://localhost || exit 1
    
    CMD ["nginx", "-g", "daemon off;"]