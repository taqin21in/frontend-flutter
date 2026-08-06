FROM nginx:1.27-alpine

# Hapus default website
RUN rm -rf /usr/share/nginx/html/*

# Copy hasil build Flutter
COPY build/web /usr/share/nginx/html

# Copy konfigurasi Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]