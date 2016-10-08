# spark
# - build with netlib-java
# http://qiita.com/adachij2002/items/b9af506d704434f4f293

FROM takaomag/openblas:release-0.2.19-2016.10.08.05.05

ENV \
    X_DOCKER_REPO_NAME=spark \
#    X_SPARK_VERSION=2.0.1-SNAPSHOT \
    X_SPARK_VERSION=2.0.1 \
#    X_SPARK_CLONE_REPO_CMD="git clone -b branch-2.0 git://git.apache.org/spark.git" \
#    X_SPARK_DOWNLOAD_URI="https://github.com/apache/spark/archive/v2.0.0-rc1.tar.gz" \
#    X_SPARK_DOWNLOAD_URI="http://ftp.riken.jp/net/apache/spark/spark-2.0.1/spark-2.0.1.tgz" \
    SPARK_HOME=/opt/local/spark \
    PYSPARK_DRIVER_PYTHON=/opt/local/python-${X_PY3_VERSION}/bin/python3 \
    PYSPARK_PYTHON=/opt/local/python-${X_PY3_VERSION}/bin/python3 \
    SPARK_EXECUTOR_URI=file:///opt/local/spark/dist/spark-2.0.1-bin-${X_HADOOP_VERSION}.tgz

RUN \
    echo "2016-05-06-1" > /dev/null && \
    export TERM=dumb && \
    export LANG='en_US.UTF-8' && \
    source /opt/local/bin/x-set-shell-fonts-env.sh && \
    echo -e "${FONT_INFO}[INFO] Updating package database${FONT_DEFAULT}" && \
    reflector --latest 100 --verbose --sort score --save /etc/pacman.d/mirrorlist && \
    sudo -u nobody yaourt -Syy && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Updated package database${FONT_DEFAULT}" && \
    echo -e "${FONT_INFO}[INFO] Refreshing package developer keys${FONT_DEFAULT}" && \
    pacman-key --refresh-keys && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Refreshed package developer keys${FONT_DEFAULT}" && \
    # required by mesos native library
    REQUIRED_PACKAGES=("boost" "gperftools" "google-glog" "leveldb" "protobuf" "protobuf-java" "picojson-git") && \
    echo -e "${FONT_INFO}[INFO] Installing required packages [${REQUIRED_PACKAGES[@]}]${FONT_DEFAULT}" && \
    mkdir /.m2 && \
    chown nobody:nobody /.m2 && \
    sudo -u nobody yaourt -S --needed --noconfirm --noprogressbar "${REQUIRED_PACKAGES[@]}" && \
    rm -rf /.m2 && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed required packages [${REQUIRED_PACKAGES[@]}]${FONT_SUCCESS}" && \
    echo -e "${FONT_INFO}[INFO] Installing spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    ([ -d /opt/local ] || mkdir -p /opt/local) && \
    cd /var/tmp && \
    if [[ "${X_SPARK_CLONE_REPO_CMD}" ]];then\
      ${X_SPARK_CLONE_REPO_CMD} && mv spark spark-${X_SPARK_VERSION};\
    elif [[ "${X_SPARK_DOWNLOAD_URI}" ]];then\
      curl --silent --location --fail --retry 5 "${X_SPARK_DOWNLOAD_URI}" | tar xz;\
    else\
      APACHE_CLOSER_MIRROR=$(curl --silent --location --fail --retry 5 --stderr /dev/null "https://www.apache.org/dyn/closer.cgi?as_json=1" | jq -r '.preferred') && \
      curl --silent --location --fail --retry 5 "${APACHE_CLOSER_MIRROR}spark/spark-${X_SPARK_VERSION}/spark-${X_SPARK_VERSION}.tgz" | tar xz;\
    fi; \
    cd spark-${X_SPARK_VERSION} && \
    # export X_SPARK_VERSION=$(build/mvn help:evaluate -Dexpression=project.version -Pyarn -Phadoop-2.7 -Dhadoop.version=${X_HADOOP_VERSION} -Phive -Phive-thriftserver -Pnetlib-lgpl 2>/dev/null | grep -v "INFO" | tail -n 1) && \
    X_SPARK_VERSION_MAJOR=$(cut -d '.' -f 1 <<< ${X_SPARK_VERSION}) && \
    [[ -f ./make-distribution.sh ]] && MAKE_DIST_PATH='./make-distribution.sh' || MAKE_DIST_PATH='dev/make-distribution.sh' && \
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk && \
    export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m" && \
    if [[ ${X_SPARK_VERSION_MAJOR} -ge 2 ]];then\
      ${MAKE_DIST_PATH} --tgz -Pyarn -Phadoop-2.7 -Dhadoop.version=${X_HADOOP_VERSION} -Phive -Phive-thriftserver -Pnetlib-lgpl;\
    else\
      ${MAKE_DIST_PATH} --tgz --skip-java-test --with-tachyon -Pyarn -Phadoop-2.6 -Dhadoop.version=${X_HADOOP_VERSION} -Phive -Phive-thriftserver -Pnetlib-lgpl;\
    fi; \
    porg --log --package="spark-${X_SPARK_VERSION}" -- mv dist /opt/local/spark-${X_SPARK_VERSION} && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ -- mkdir /opt/local/spark-${X_SPARK_VERSION}/dist && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ -- mv spark-${X_SPARK_VERSION}*.tgz /opt/local/spark-${X_SPARK_VERSION}/dist/. && \
    cd /opt/local && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ -- ln -sf spark-${X_SPARK_VERSION} spark && \
    rm -rf /var/tmp/spark-${X_SPARK_VERSION} && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    /opt/local/bin/x-archlinux-remove-unnecessary-files.sh && \
#    pacman-optimize && \
    rm -f /etc/machine-id

# spark.mesos.executor.docker.image assumes the default working directory of the container to be inside $SPARK_HOME.
WORKDIR /opt/local/spark

#    mvn -Pyarn -Phadoop-2.4 -Dhadoop.version=2.6.0 -Phive -Phive-thriftserver -DskipTests clean package && \
# envs
# SPARK_HOME
# SPARK_CONF_DIR
# PYSPARK_PYTHON
# PYSPARK_DRIVER_PYTHON
# SPARKR_DRIVER_R
# SPARK_LOCAL_IP
# SPARK_PUBLIC_DNS
# SPARK_LOCAL_DIRS (standalone or mesos)
# LOCAL_DIRS (yarn)
# SPARK_EXECUTOR_URK (for mesos)
