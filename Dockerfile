FROM nginx:1.8

#Install Curl
RUN apt-get update -qq && apt-get -y install curl && apt-get install unzip

#Download and Install Consul Template
ENV CT_URL https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip
RUN curl -L $CT_URL -o consul-template.zip
RUN unzip -d /usr/local/bin/ consul-template.zip

#Setup Consul Template Files
RUN mkdir /etc/consul-templates
ENV CT_FILE /etc/consul-templates/nginx.conf
ENV NX_FILE /etc/nginx/nginx.conf

#Default Variables
ENV CONSUL consul:8500
ENV SERVICE consul-agent-8500

#Setup Nginx File
ADD ./api.ctmpl $CT_FILE

CMD /usr/sbin/nginx -c $NX_FILE \
& CONSUL_TEMPLATE_LOG=debug /usr/local/bin/consul-template \
  -consul=$CONSUL \
  -template "$CT_FILE:$NX_FILE:/usr/sbin/nginx -s reload";