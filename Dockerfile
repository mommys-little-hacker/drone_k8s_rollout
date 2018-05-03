FROM lachlanevenson/k8s-kubectl

RUN apk update \
  && apk add curl bash \
  && rm /var/cache/apk/*

COPY rollout.sh /root
RUN chmod +x /root/rollout.sh

ENV PLUGIN_KIND=deployment
ENV PLUGIN_OBJECT=""
ENV PLUGIN_IMGS=""
ENV PLUGIN_CNTS=""
ENV PLUGIN_TAGS=""

ENV PLUGIN_CA=""
ENV PLUGIN_TOKEN=""
ENV PLUGIN_ADDR=""
ENV PLUGIN_USER="admin"

ENTRYPOINT [ "bash", "/root/rollout.sh" ]