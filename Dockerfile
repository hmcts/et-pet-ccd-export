FROM ruby:2.7.5-alpine

RUN addgroup app --gid 1000
RUN adduser -SD -u 1000 --shell /bin/bash --home /home/app app app


ARG APPVERSION=unknown
ARG APP_BUILD_DATE=unknown
ARG APP_GIT_COMMIT=unknown
ARG APP_BUILD_TAG=unknown

# Setting up ping.json variables
ENV APPVERSION ${APPVERSION}
ENV APP_BUILD_DATE ${APP_BUILD_DATE}
ENV APP_GIT_COMMIT ${APP_GIT_COMMIT}
ENV APP_BUILD_TAG ${APP_BUILD_TAG}

EXPOSE 8080

COPY --chown=app:app . /home/app/ccd-export
RUN chown -R app:app /usr/local/bundle
RUN apk add --no-cache tzdata gettext shared-mime-info libc6-compat bash && \
    apk add --no-cache --virtual .build-tools git build-base && \
    cd /home/app/ccd-export && \
    gem install bundler -v 1.17.3 && \
    bundle install --no-cache --jobs=5 --retry=3 --without=test development --with=production --deployment && \
    apk del .build-tools && \
    chown -R app:app /usr/local/bundle && \
    mkdir -p /home/app/ccd-export/tmp && \
    chown -R app:app /home/app/ccd-export/tmp


USER app
ENV HOME /home/app
WORKDIR /home/app/ccd-export
ENV RAILS_ENV=production
CMD ["bundle", "exec", "./bin/sidekiq", "--config", "config/sidekiq.yml"]
