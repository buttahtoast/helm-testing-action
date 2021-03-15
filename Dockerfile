FROM alpine

COPY ./scripts /scripts
COPY ./selector.sh /

RUN apk add --no-cache ca-certificates curl bash git openssl jq perl-utils \
  && chmod +x -R /scripts ./selector.sh \
  && curl -fsSLo get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
  && chmod 700 get_helm.sh \
  && ./get_helm.sh \
  && curl -sL "https://github.com/stackrox/kube-linter/releases/download/$(curl --silent "https://api.github.com/repos/stackrox/kube-linter/releases/latest" | jq -r .tag_name)/kube-linter-linux.tar.gz" | tar xz \
  && chmod +x ./kube-linter \
  && mv ./kube-linter /usr/local/bin/ \
  && curl -s -L -o /usr/local/bin/spruce https://github.com/geofffranks/spruce/releases/download/$(curl --silent "https://api.github.com/repos/geofffranks/spruce/releases/latest" | jq -r .tag_name)/spruce-linux-amd64 \
  && chmod +x /usr/local/bin/spruce \
  && curl -s -L -o /usr/local/bin/helm-docs.tar.gz "https://github.com/norwoodj/helm-docs/releases/download/$(curl --silent "https://api.github.com/repos/norwoodj/helm-docs/releases/latest" | jq -r .tag_name)/helm-docs_$(curl --silent "https://api.github.com/repos/norwoodj/helm-docs/releases/latest" | jq -r .tag_name | cut -d "v" -f2-)_Linux_x86_64.tar.gz" \
  && cd /usr/local/bin/ && tar xfv helm-docs.tar.gz \ 
  && chmod +x ./helm-docs

CMD [ "/bin/bash", "/selector.sh" ]

