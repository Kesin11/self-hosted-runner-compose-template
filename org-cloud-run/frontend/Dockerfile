FROM node:14-slim

COPY index.js package.json package-lock.json /
RUN npm ci --production && rm -rf ~/.npm

ENTRYPOINT ["npm"]
CMD ["run", "start"]