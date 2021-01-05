FROM alpine

## Environment Variables
##
ENV CR_VERSION "1.0.0-beta.1"

## Copy Content
##
COPY . /usr/local/src/

## Install Dependencies
##
RUN apk add --no-cache ca-certificates curl bash git openssl jq && \
  chmod +x -R /usr/local/src/ && \
  curl -fsSLo get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh && \
  curl -sL "https://github.com/helm/chart-releaser/releases/download/v${CR_VERSION}/chart-releaser_${CR_VERSION}_linux_amd64.tar.gz" | tar zx && \
  chmod +x ./cr && \
  mv ./cr /usr/local/bin/ && \
  curl -sL "https://github.com/stackrox/kube-linter/releases/download/$(curl --silent "https://api.github.com/repos/stackrox/kube-linter/releases/latest" | jq -r .tag_name)/kube-linter-linux.tar.gz" | tar xz && \
  chmod +x ./kube-linter && \
  mv ./kube-linter /usr/local/bin/ && \
  curl -s -L -o /usr/local/bin/spruce https://github.com/geofffranks/spruce/releases/download/$(curl --silent "https://api.github.com/repos/geofffranks/spruce/releases/latest" | jq -r .tag_name)/spruce-linux-amd64 && \
  chmod +x /usr/local/bin/spruce

## Execute Action Handler
##
CMD [ "bash", "/usr/local/src/release.sh" ]
