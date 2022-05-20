FROM nginx:1-alpine


ENV NGINX_HOST=blog.dsal3389.xyz

WORKDIR /public
COPY ./public/* .

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
