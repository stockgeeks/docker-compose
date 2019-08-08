#!/bin/bash -e

# connector start command here.
exec "/opt/kafka/bin/connect-standalone.sh" "/opt/kafka/config/connect-standalone.properties" "/opt/kafka/config/connect-file-source.properties"
