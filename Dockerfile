FROM nginx:1.8

#Install Curl
RUN apt-get update -qq && apt-get -y install curl

#Download and Install Consul Template
ENV CT_URL https://github.com/hashicorp/consul-template/archive/v0.12.1.tar.gz
RUN curl -L $CT_URL | \
tar -C /usr/local/bin --strip-components 1 -zxf -

#Setup Consul Template Files
RUN mkdir /etc/consul-templates
ENV CT_FILE /etc/consul-templates/nginx.conf

#Setup Nginx File
ENV NX_FILE /etc/nginx/nginx.conf
ADD ./nginx.conf $NX_FILE


#Default Variables
ENV CONSUL consul:8500
ENV SERVICE consul-agent-8500

# Command will
# 1. Write Consul Template File
# 2. Start Nginx
# 3. Start Consul Template

CMD echo "upstream app {                 \n\
  least_conn;                            \n\
  {{range service \"$SERVICE\"}}         \n\
  server  {{.Address}}:{{.Port}};        \n\
  {{else}}server 127.0.0.1:65535;{{end}} \n\
}                                        \n\
server {                                 \n\
  listen 80 default_server;              \n\
  location / {                           \n\
    proxy_pass http://app;               \n\
  }                                      \n\
}" > $CT_FILE; \
/usr/sbin/nginx -c $NX_FILE \
& CONSUL_TEMPLATE_LOG=debug consul-template \
  -consul=$CONSUL \
  -template "$CT_FILE:$NX_FILE:/usr/sbin/nginx -s reload";