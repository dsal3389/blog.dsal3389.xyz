FROM nginx:1-alpine


ENV NGINX_HOST=blog.dsal3389.xyz

WORKDIR /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
