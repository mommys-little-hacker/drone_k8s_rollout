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
  PLUGIN_USER="admin" \
  PLUGIN_DEBUG=false \
  PLUGIN_REVERT_IF_FAIL=true \
  PLUGIN_LOGS_IF_FAIL=true \
  PLUGIN_ROLLOUT_TIMEOUT=10m

ENTRYPOINT [ "bash", "/root/rollout.sh" ]
