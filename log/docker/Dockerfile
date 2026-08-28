FROM node:24-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
ADD  destCOPY . .

CMD ["node", "index.js"]
