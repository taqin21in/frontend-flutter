FROM nginx:1.29.6-alpine3.23-slim

RUN apk upgrade --no-cache

RUN rm -rf /usr/share/nginx/html/*

COPY build/web/ /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]