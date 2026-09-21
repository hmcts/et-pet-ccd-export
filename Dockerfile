# Temporary deployment placeholder while the exporter moves into the API.
# Keep the existing Helm health checks working without starting Rails or Sidekiq.
FROM busybox:1.38.0

ARG APPVERSION=unknown
ARG APP_BUILD_DATE=unknown
ARG APP_GIT_COMMIT=unknown
ARG APP_BUILD_TAG=unknown

ENV APPVERSION=${APPVERSION}
ENV APP_BUILD_DATE=${APP_BUILD_DATE}
ENV APP_GIT_COMMIT=${APP_GIT_COMMIT}
ENV APP_BUILD_TAG=${APP_BUILD_TAG}

RUN mkdir -p /www && printf 'OK\n' > /www/health && chown -R 1000:1000 /www

USER 1000:1000
EXPOSE 7433
CMD ["httpd", "-f", "-p", "0.0.0.0:7433", "-h", "/www"]
