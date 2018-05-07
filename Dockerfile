FROM lachlanevenson/k8s-kubectl

COPY rollout.sh /root

RUN apk update \
  && apk add curl bash \
  && rm /var/cache/apk/* \
  && chmod +x /root/rollout.sh

ENV PLUGIN_KIND="deployment"
ENV PLUGIN_OBJECT=""
ENV PLUGIN_IMG_NAMES=""
ENV PLUGIN_IMG_CNTS=""
ENV PLUGIN_IMG_TAGS=""

ENV PLUGIN_CA=""
ENV PLUGIN_TOKEN=""
ENV PLUGIN_ADDR=""
ENV PLUGIN_USER="admin"

ENTRYPOINT [ "bash", "/root/rollout.sh" ]
