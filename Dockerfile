# Usa la imagen oficial de Node.js
FROM node:20-alpine AS builder

# Directorio de trabajo
WORKDIR /app

# Copia los archivos de configuración del proyecto
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# Instala dependencias (usa el gestor de paquetes que prefieras)
RUN npm install

# Copia el resto del código fuente
COPY . .

# Copia el archivo .env.prod como .env (para que Next.js lo use durante el build)
COPY .env.local .env
ENV NODE_OPTIONS="--max-old-space-size=4096"
# Build de la aplicación (esto incluirá las variables de entorno en el código final)
RUN npm run build

# Imagen final con solo los archivos necesarios
FROM node:20-alpine AS runner
WORKDIR /app

# Copia el build y las dependencias necesarias
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./next.config.mjs
COPY --from=builder /app/postcss.config.mjs ./postcss.config.mjs
COPY --from=builder /app/tailwind.config.ts ./tailwind.config.ts
COPY --from=builder /app/tsconfig.json ./tsconfig.json
COPY --from=builder /app/.env.local ./.env.local

# Expone el puerto y ejecuta la aplicación
EXPOSE 3000
CMD ["npm", "start"]