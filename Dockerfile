FROM node:20

WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE ${BE_SERVER_PORT}
CMD ["npm", "start"]
