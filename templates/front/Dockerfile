# Build de la SPA (Vite) puis service par nginx.
# Les variables VITE_* sont figées dans le bundle au build : les passer en --build-arg.
FROM node:20-alpine AS build
WORKDIR /app

# Le yarn.lock pointe vers le registre npm privé : le .npmrc (avec jeton) est monté
# en secret BuildKit le temps de l'install, il n'est jamais écrit dans l'image.
COPY package.json yarn.lock ./
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc yarn install --frozen-lockfile

COPY . .

ARG VITE_ENABLE_AUTH
ARG VITE_TENANT_ID
ARG VITE_FRONT_CLIENT_ID
ARG VITE_API_CLIENT_ID
ARG VITE_API_BASE_URL
ARG VITE_REDIRECT_URI
ARG VITE_BUILD_NUMBER
ARG VITE_BUILD_COMMIT
ARG VITE_BUILD_BRANCH
ARG VITE_BUILD_ENV
ENV VITE_ENABLE_AUTH=$VITE_ENABLE_AUTH \
    VITE_TENANT_ID=$VITE_TENANT_ID \
    VITE_FRONT_CLIENT_ID=$VITE_FRONT_CLIENT_ID \
    VITE_API_CLIENT_ID=$VITE_API_CLIENT_ID \
    VITE_API_BASE_URL=$VITE_API_BASE_URL \
    VITE_REDIRECT_URI=$VITE_REDIRECT_URI \
    VITE_BUILD_NUMBER=$VITE_BUILD_NUMBER \
    VITE_BUILD_COMMIT=$VITE_BUILD_COMMIT \
    VITE_BUILD_BRANCH=$VITE_BUILD_BRANCH \
    VITE_BUILD_ENV=$VITE_BUILD_ENV

RUN yarn build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
