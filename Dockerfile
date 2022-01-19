FROM eclipse-temurin:11-alpine

# Install required packages
RUN apk add --no-cache \
    bash \
    gettext \
    su-exec \
    tini

# UID & GID for non-root user
ARG uid=10001
ARG gid=10001

# Non-root user for security purposes.
#
# A UID/GID above 10,000 is less likely to 
# map to a more privileged user on the host
# in the case of a container breakout.
RUN addgroup --gid ${uid} --system nonroot \
 && adduser --uid ${gid} --system \
 --ingroup nonroot --disabled-password nonroot

# Initial and max heap size for the java application
ARG heap_size=1G
ENV HEAP_SIZE=$heap_size

# JVM Flags
ARG java_tool_options="-XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:+UnlockExperimentalVMOptions \
-XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -XX:MaxInlineLevel=15"
ENV JAVA_TOOL_OPTIONS=$java_tool_options

# URL for the Velocity jar
ARG velocity_jar_url=https://papermc.io/api/v2/projects/velocity/versions/3.1.1/builds/98/downloads/velocity-3.1.1-98.jar
ENV VELOCITY_JAR_URL=$velocity_jar_url

# Add the Velocity jar
ADD --chown=nonroot:nonroot ${VELOCITY_JAR_URL} /opt/velocity/velocity.jar

# Copy scripts
COPY scripts/ /usr/local/bin/
RUN chmod -R +x /usr/local/bin

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Copy secrets
ARG secrets_path=/.secrets
COPY secrets/ $secrets_path

# Copy server files
ARG data_path=/home/nonroot/velocity
ENV DATA_PATH=$data_path
COPY --chown=nonroot:nonroot server/ $data_path

# Create data dirs
ARG plugin_data_path=/plugin_data
ENV PLUGIN_DATA_PATH=$plugin_data_path
RUN mkdir -p $plugin_data_path $data_path/logs \
  && chown -R nonroot:nonroot $plugin_data_path $data_path/logs

# Persistent data
VOLUME $plugin_data_path $data_path/logs

# Substitute envvars
RUN /usr/local/bin/substitute_envvars.sh ${data_path} ${secrets_path}

WORKDIR $data_path
