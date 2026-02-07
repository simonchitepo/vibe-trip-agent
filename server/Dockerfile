FROM node:20-alpine

# ✅ Fix HTTPS/TLS issues (OpenAI API calls need this)
RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY index.js ./

ENV PORT=8080
EXPOSE 8080

CMD ["node", "index.js"]
