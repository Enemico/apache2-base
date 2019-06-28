FROM enemico/chaperone

COPY build.sh /tmp/build.sh
COPY conf /tmp/conf
COPY var /tmp/var
COPY setup-apache.sh /usr/local/bin/setup-apache.sh

RUN /tmp/build.sh && rm /tmp/build.sh
