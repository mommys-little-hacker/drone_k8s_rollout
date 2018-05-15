FROM lachlanevenson/k8s-kubectl

COPY rollout.sh /root

RUN apk update \
  && apk add curl bash \
  && rm /var/cache/apk/* \
  && chmod +x /root/rollout.sh

ENV PLUGIN_KIND="deployment" \
  PLUGIN_OBJECT="" \
  PLUGIN_NAMESPACE="default" \
  PLUGIN_IMG_NAMES="" \
  PLUGIN_IMG_CNTS="" \
  PLUGIN_IMG_TAGS="" \
  PLUGIN_CA="" \
  PLUGIN_TOKEN="" \
  PLUGIN_ADDR="" \
  PLUGIN_USER="admin" \
  PLUGIN_DEBUG=false

ENTRYPOINT [ "bash", "/root/rollout.sh" ]
