FROM alpine

## Environment Variables
##
ENV CR_VERSION "1.0.0-beta.1"

## Copy Content
##
COPY . /usr/local/src/

## Install Dependencies
##
RUN apk add --no-cache ca-certificates curl bash git openssl && \
  chmod +x -R /usr/local/src/ && \
  curl -fsSLo get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
  chmod 700 get_helm.sh && \
  ./get_helm.sh && \
  curl -sL "https://github.com/helm/chart-releaser/releases/download/v${CR_VERSION}/chart-releaser_${CR_VERSION}_linux_amd64.tar.gz" | tar zx && \
  chmod +x ./cr && \
  mv ./cr /usr/local/bin/

## Install Helm Plugins
##
RUN helm plugin install https://github.com/karuppiah7890/helm-schema-gen

## Execute Action Handler
##
CMD [ "bash", "/usr/local/src/release.sh" ]
