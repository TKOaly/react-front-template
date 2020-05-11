FROM node:13.0.0

WORKDIR /app

COPY public /app/public
COPY src /app/src
COPY package.json /app/
COPY webpack.config.js /app/
COPY yarn.lock /app/
COPY tsconfig.json /app/

RUN yarn install

EXPOSE 5050

CMD ["yarn", "start"]
