# Build stage
FROM node:18 AS build

WORKDIR /app

# Copy package files
COPY package.json ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install

# Copy the rest of the application code
COPY . .

# Build the SvelteKit app and compile lambda.ts
RUN pnpm run build

# Lambda stage
FROM public.ecr.aws/lambda/nodejs:18

WORKDIR ${LAMBDA_TASK_ROOT}

# Copy built assets from the build stage
COPY --from=build /app/build ./
COPY --from=build /app/.svelte-kit ./.svelte-kit
COPY --from=build /app/lambda-handler.js ./lambda-handler.js

# Copy node_modules
COPY --from=build /app/node_modules ./node_modules

# Copy package.json (might be needed for some setups)
COPY --from=build /app/package.json ./package.json

# Set the CMD to your handler
CMD [ "lambda-handler.handler" ]