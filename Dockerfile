# Use the Node.js 18 LTS image as the base
FROM node:18 AS builder

RUN echo "Set the working directory in the container"
WORKDIR /app

RUN echo "Copy package.json and package-lock.json (if available) from the source folder to the container"
COPY package*.json ./

RUN echo "Installing npm dependencies"
RUN npm install

##################################### PRISMA BUILDING ######################################################

# Create the prisma folder
RUN mkdir prisma

# Write the Prisma schema to prisma/schema.prisma dynamically
COPY prisma/schema.prisma  ./prisma

# Set environment variable for SQLite database
ENV DATABASE_URL="file:./dev.db"

# Generate Prisma Client
RUN npx prisma generate

# Run Prisma migrations
RUN npx prisma migrate dev --name init

############################################################################################################

RUN echo "Copy the entire application source code from the source folder to the container"
COPY . . 

RUN echo "Build the Next.js application"
RUN npm run build

# Use a minimal Node.js image to reduce the container size for production
FROM node:18-alpine AS runner

# Set the working directory in the container
WORKDIR /app

# Install only production dependencies
COPY package*.json ./
RUN npm install --production

# Copy the built application from the builder stage
COPY --from=builder /app/.next /app/.next
COPY --from=builder /app/public /app/public
#COPY --from=builder /app/next.config.js /app/next.config.js
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/prisma /app/prisma

ENV DATABASE_URL="file:./dev.db"

# Run Prisma migrations
#RUN npx prisma migrate dev --name init

# Expose the port Next.js will run on
EXPOSE 3000

# Start the Next.js application
CMD ["npm", "start"]