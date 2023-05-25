FROM node:12.22.11-alpine as Builder

RUN mkdir -p /home/openeuler/QARobot
WORKDIR /home/openeuler/QARobot
COPY . /home/openeuler/QARobot

RUN npm config set registry https://registry.npm.taobao.org
RUN npm install
RUN npm run build

FROM nginx:1.25

RUN sed -i 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS   0/' /etc/login.defs
RUN mkdir -p /opt/QARobot
COPY --from=Builder /home/openeuler/QARobot/dist /opt/QARobot
RUN chmod -R 755 /opt/QARobot
COPY ./deploy/qarobot.conf /etc/nginx/conf.d/

ENV RUN_USER nginx
ENV RUN_GROUP nginx
EXPOSE 8080
ENTRYPOINT [ "nginx", "-g", "daemon off;" ]
