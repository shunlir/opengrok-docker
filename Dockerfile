FROM tomcat:9-jre8-slim
ARG version
MAINTAINER Shunli Ren"shunli.ren.00@gmail.com"

RUN sed -i '/main$/ s/$/ universe/' /etc/apt/sources.list

# install dependencies
RUN set -ex; \
    apt-get update && apt-get install -y --no-install-recommends git subversion mercurial unzip inotify-tools python3 python3-pip python3-setuptools; \
    rm -rf /var/lib/apt/lists/*
# compile and install universal-ctags
RUN set -ex; \
    apt-get update && apt-get install -y --no-install-recommends pkg-config autoconf automake build-essential; \
    rm -rf /var/lib/apt/lists/*; \
    git clone https://github.com/universal-ctags/ctags /root/ctags ; \
    cd /root/ctags && ./autogen.sh && ./configure && make && make install ; \
    apt-get remove -y autoconf automake build-essential && apt-get -y autoremove && apt-get -y autoclean ; \
    cd /root && rm -rf /root/ctags

# download opengrok and extract
RUN set -ex; \
    apt-get update && apt-get install -y --no-install-recommends curl jq wget && rm -rf /var/lib/apt/lists/*; \
    if [ -z "$version" ]; then \
      /bin/bash -c "set -exo pipefail; \
        curl -sS https://api.github.com/repos/oracle/opengrok/releases | \
          jq -er '.[0].assets[]|select(.name|test(\"opengrok-.*tar.gz\"))|.browser_download_url' | \
          wget --no-verbose -i - -O /tmp/opengrok.tar.gz"; \
    else \
      wget --no-verbose -O /tmp/opengrok.tar.gz "https://github.com/oracle/opengrok/releases/download/$version/opengrok-$version.tar.gz"; \
    fi; \
    mkdir -p /grok/dist; \
    tar -zxvf /tmp/opengrok.tar.gz -C /grok/dist --strip-components 1; rm -f /tmp/opengrok.tar.gz; \
    python3 -m pip install /grok/dist/tools/opengrok-tools*; \
    mkdir /var/opengrok; \
    mkdir /grok/etc && ln -s /grok/etc /var/opengrok/etc; \
    mkdir /grok/data && ln -s /grok/data /var/opengrok/data; \
    mkdir /grok/src && ln -s /grok/src /var/opengrok/src; \
    mkdir /grok/log && ln -s /grok/log /var/opengrok/log; \
    cp /grok/dist/doc/logging.properties /grok/etc/; \
    cp /grok/dist/doc/logging.properties.template /grok/etc/; \
    sed -i -E 's@^(java.util.logging.FileHandler.pattern).*@\1 = /var/opengrok/log/opengrok%g.%u.log@g' /var/opengrok/etc/logging.properties; \
    sed -i -E 's@^(java.util.logging.FileHandler.pattern).*@\1 = /var/opengrok/log/%PROJ%/opengrok%g.%u.log@g' /var/opengrok/etc/logging.properties.template; \
    sed -i -E 's@^(java.util.logging.FileHandler.count).*@\1 = 3@g' /var/opengrok/etc/logging.properties.template

# env
ENV GROK_INST /var/opengrok
ENV GROK_DIST /grok/dist
ENV GROK_ETC $GROK_INST/etc
ENV GROK_LOG $GROK_INST/log
ENV GROK_JAR $GROK_DIST/lib/opengrok.jar
ENV SRC_ROOT $GROK_INST/src
ENV DATA_ROOT $GROK_INST/data
ENV OPENGROK_WEBAPP_CONTEXT /
ENV OPENGROK_TOMCAT_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH:/grok/bin
ENV CATALINA_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV CATALINA_TMPDIR /usr/local/tomcat/temp
ENV JRE_HOME /usr
ENV CLASSPATH /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar

# deploy
RUN set -ex; \
    opengrok-deploy /grok/dist/lib/source.war /usr/local/tomcat/webapps/ ; \
    rm -rf /usr/local/tomcat/webapps/ROOT/* ; \
    echo '<% response.sendRedirect("/source"); %>' > "/usr/local/tomcat/webapps/ROOT/index.jsp"

# add files
COPY fs/opt/bin /grok/bin
RUN chmod -R +x /grok/bin
COPY fs/var/opengrok/etc/* /var/opengrok/etc/

# tomcat logging tuning: keep 10 days
RUN set -ex; sed -i -E 's/(maxDays.*=.*)90/\10/g' /usr/local/tomcat/conf/logging.properties

# run
WORKDIR $CATALINA_HOME
EXPOSE 8080
CMD ["/grok/bin/run.sh"]
