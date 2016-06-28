# spark
# - build with netlib-java
# http://qiita.com/adachij2002/items/b9af506d704434f4f293

FROM takaomag/base:2016.06.07.07.30

ENV \
    X_DOCKER_REPO_NAME=spark \
    X_SPARK_VERSION=2.0.0-rc1 \
#    X_SPARK_CLONE_REPO_CMD="git clone -b branch-2.0 git://git.apache.org/spark.git" \
    X_SPARK_DOWNLOAD_URI="https://github.com/apache/spark/archive/v2.0.0-rc1.tar.gz" \
    PYSPARK_DRIVER_PYTHON=/opt/local/python-${X_PY3_VERSION}/bin/python3 \
    PYSPARK_PYTHON=/opt/local/python-${X_PY3_VERSION}/bin/python3

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
    REQUIRED_PACKAGES=("gcc-fortran" "atlas-lapack-base") && \
    echo -e "${FONT_INFO}[INFO] Installing required packages [${REQUIRED_PACKAGES[@]}]${FONT_DEFAULT}" && \
    sudo -u nobody yaourt -S --needed --noconfirm --noprogressbar "${REQUIRED_PACKAGES[@]}" && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed required packages [${REQUIRED_PACKAGES[@]}]${FONT_DEFAULT}" && \
    echo -e "${FONT_INFO}[INFO] Installing netlib-java=1.1.2${FONT_DEFAULT}" && \
    cd /var/tmp && \
    git clone https://github.com/fommil/netlib-java.git && \
    cd netlib-java && \
    git checkout -b 1.1.2 refs/tags/1.1.2 && \
    sed -i "s/1.2-SNAPSHOT/1.1.2/g" `grep -l 1.2-SNAPSHOT pom.xml perf/pom.xml legacy/pom.xml` && \
    sed -i "s/1.1.1/1.1.2/g" `grep -l 1.1.1 generator/pom.xml core/pom.xml all/pom.xml` && \
    sed -i "s/1.2-SNAPSHOT/1.1/g" `grep -rl --include='pom.xml' 1.2-SNAPSHOT native_ref native_system` && \
    mvn -fn package && \
    cd native_system && \
    mvn -fn package && \
    cd xbuilds/linux-x86_64 && \
    mvn -fn package && \
    cd ../../../native_ref && \
    mvn -fn package && \
    cd xbuilds/linux-x86_64 && \
    mvn -fn package && \
    mv /var/tmp/netlib-java/native_system/xbuilds/linux-x86_64/target/netlib-native_system-linux-x86_64.so /usr/lib/libnetlib-native_system-linux-x86_64.so && \
    mv /var/tmp/netlib-java/native_ref/xbuilds/linux-x86_64/target/netlib-native_ref-linux-x86_64.so /usr/lib/libnetlib-native_ref-linux-x86_64.so && \
    ldconfig && \
    cd /var/tmp && \
    rm -rf /var/tmp/netlib-java && \
    echo -e "${FONT_INFO}[INFO] Installed netlib-java=1.1.2${FONT_DEFAULT}" && \
    echo -e "${FONT_INFO}[INFO] Installing spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    ([ -d /opt/local ] || mkdir -p /opt/local) && cd /var/tmp && \
    if [[ "${X_SPARK_CLONE_REPO_CMD}" ]];then\
      ${X_SPARK_CLONE_REPO_CMD} && mv spark spark-${X_SPARK_VERSION};\
    elif [[ "${X_SPARK_DOWNLOAD_URI}" ]];then\
      curl --fail --silent --location "${X_SPARK_DOWNLOAD_URI}" | tar xz;\
    else\
      curl --fail --silent --location "http://ftp.riken.jp/net/apache/spark/spark-${X_SPARK_VERSION}/spark-${X_SPARK_VERSION}.tgz" | tar xz;\
    fi; \
    cd spark-${X_SPARK_VERSION} && \
    # export X_SPARK_VERSION=$(build/mvn help:evaluate -Dexpression=project.version -Pyarn -Phadoop-2.7 -Dhadoop.version=2.7.2 -Phive -Phive-thriftserver -Pnetlib-lgpl 2>/dev/null | grep -v "INFO" | tail -n 1) && \
    X_SPARK_VERSION_MAJOR=$(cut -d '.' -f 1 <<< ${X_SPARK_VERSION}) && \
    [[ -f ./make-distribution.sh ]] && MAKE_DIST_PATH='./make-distribution.sh' || MAKE_DIST_PATH='dev/make-distribution.sh' && \
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk && \
    export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m" && \
    if [[ ${X_SPARK_VERSION_MAJOR} -ge 2 ]];then\
      ${MAKE_DIST_PATH} --tgz -Pyarn -Phadoop-2.7 -Dhadoop.version=2.7.2 -Phive -Phive-thriftserver -Pnetlib-lgpl;\
    else\
      ${MAKE_DIST_PATH} --tgz --skip-java-test --with-tachyon -Pyarn -Phadoop-2.6 -Dhadoop.version=2.7.2 -Phive -Phive-thriftserver -Pnetlib-lgpl;\
    fi; \
    porg --log --package="spark-${X_SPARK_VERSION}" -- mv dist /opt/local/spark-${X_SPARK_VERSION} && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ mkdir /opt/local/spark-${X_SPARK_VERSION}/dist && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ mv spark-${X_SPARK_VERSION}*.tgz /opt/local/spark-${X_SPARK_VERSION}/dist/. && \
    cd /opt/local && \
    ln -sf spark-${X_SPARK_VERSION} spark && \
    rm -rf /var/tmp/spark-${X_SPARK_VERSION} && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    /opt/local/bin/x-archlinux-remove-unnecessary-files.sh && \
#    pacman-optimize && \
    rm -f /etc/machine-id

#    mvn -Pyarn -Phadoop-2.4 -Dhadoop.version=2.6.0 -Phive -Phive-thriftserver -DskipTests clean package && \
