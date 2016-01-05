# spark

FROM takaomag/base:2015.12.07.05.00

ENV \
    X_DOCKER_REPO_NAME=spark \
    X_SPARK_VERSION=1.6.0

RUN \
    echo "2016-01-05-0" > /dev/null && \
    export TERM=dumb && \
    export LANG='en_US.UTF-8' && \
    source /opt/local/bin/x-set-shell-fonts-env.sh && \
    echo -e "${FONT_INFO}[INFO] Installing spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    ([ -d /opt/local ] || mkdir -p /opt/local) && cd /opt/local && \
    cd /tmp && \
    curl --fail --silent --location "http://ftp.riken.jp/net/apache/spark/spark-${X_SPARK_VERSION}/spark-${X_SPARK_VERSION}.tgz" | tar xz && \
    cd spark-${X_SPARK_VERSION} && \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk ./make-distribution.sh --skip-java-test --with-tachyon --tgz -Pyarn -Phadoop-2.6 -Dhadoop.version=2.7.1 -Phive -Phive-thriftserver && \
    porg --log --package="spark-${X_SPARK_VERSION}" -- mv dist /opt/local/spark-${X_SPARK_VERSION} && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ mkdir /opt/local/spark-${X_SPARK_VERSION}/dist && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ mv spark-${X_SPARK_VERSION}*.tgz /opt/local/spark-${X_SPARK_VERSION}/dist/. && \
    cd /opt/local && \
    ln -sf spark-${X_SPARK_VERSION} spark && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    /opt/local/bin/x-archlinux-remove-unnecessary-files.sh && \
    pacman-optimize && \
    rm -f /etc/machine-id

#    mvn -Pyarn -Phadoop-2.4 -Dhadoop.version=2.6.0 -Phive -Phive-thriftserver -DskipTests clean package && \

