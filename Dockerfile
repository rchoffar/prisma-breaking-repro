FROM node:22.3.0-alpine3.20 AS base

FROM base AS install-prod-libs

ENV NODE_ENV build
WORKDIR /home/node

# install openssl for prisma
RUN apk add --no-cache curl openssl

COPY package.json package-lock.json prisma ./

RUN npm ci --omit=dev

#
# Dev Libs
# Prisma generation
# transpilation to JS in dist/
#
FROM install-prod-libs AS make-dist

COPY prisma ./prisma
RUN npm ci --prefer-offline
RUN npx prisma generate
COPY tsconfig.json ./

###
### Runtime
###
FROM base AS runtime

WORKDIR /home/node

COPY prisma ./prisma
COPY --from=install-prod-libs /home/node/node_modules ./node_modules

USER node

CMD ["npx", "prisma", "migrate", "deploy"]
