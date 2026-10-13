# Build de la SPA (Vite) puis service par nginx.
# Les variables VITE_* de configuration (auth, API...) sont injectées au démarrage du
# conteneur (40-runtime-env.sh) : le bundle contient des marqueurs __RUNTIME_<VAR>__.
# Seules les infos de build (VITE_BUILD_*) sont passées en --build-arg.
FROM node:20-alpine AS build
WORKDIR /app

# Le yarn.lock pointe vers le registre npm privé : le .npmrc (avec jeton) est monté
# en secret BuildKit le temps de l'install, il n'est jamais écrit dans l'image.
COPY package.json yarn.lock ./
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc yarn install --frozen-lockfile

COPY . .

ARG VITE_BUILD_NUMBER
ARG VITE_BUILD_COMMIT
ARG VITE_BUILD_BRANCH
ARG VITE_BUILD_ENV
ENV VITE_ENABLE_AUTH=__RUNTIME_VITE_ENABLE_AUTH__ \
    VITE_TENANT_ID=__RUNTIME_VITE_TENANT_ID__ \
    VITE_FRONT_CLIENT_ID=__RUNTIME_VITE_FRONT_CLIENT_ID__ \
    VITE_API_CLIENT_ID=__RUNTIME_VITE_API_CLIENT_ID__ \
    VITE_API_BASE_URL=__RUNTIME_VITE_API_BASE_URL__ \
    VITE_REDIRECT_URI=__RUNTIME_VITE_REDIRECT_URI__ \
    VITE_BUILD_NUMBER=$VITE_BUILD_NUMBER \
    VITE_BUILD_COMMIT=$VITE_BUILD_COMMIT \
    VITE_BUILD_BRANCH=$VITE_BUILD_BRANCH \
    VITE_BUILD_ENV=$VITE_BUILD_ENV

RUN yarn build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY 40-runtime-env.sh /docker-entrypoint.d/40-runtime-env.sh
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
