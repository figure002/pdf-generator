FROM eclipse-temurin:8-jdk

RUN apt-get update --yes --quiet \
 && apt-get install --yes --quiet --no-install-recommends \
    curl \
    file \
    less \
    make \
    maven \
    unzip \
    vim \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN adduser --uid=1000 java

RUN mkdir /app \
  && chown -R java:java /app

USER java

COPY --chown=java:java docker/dev-home/ /home/java/

WORKDIR /app
