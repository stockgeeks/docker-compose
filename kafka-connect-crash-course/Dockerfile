FROM wurstmeister/kafka:2.12-2.3.0

# we replace the default connect-standalone.properties so we can properly resolve to our local kafka docker development
COPY connect-standalone.properties /opt/kafka/config/

COPY connect-file-source.properties /opt/kafka/config/

# we replace the start command creating a connector instead.
COPY start-kafka.sh /usr/bin/

# permissions
RUN chmod a+x /usr/bin/start-kafka.sh
