# spark
# - build with netlib-java
# http://qiita.com/adachij2002/items/b9af506d704434f4f293

FROM takaomag/base:2016.03.08.06.57

ENV \
    X_DOCKER_REPO_NAME=spark \
    X_SPARK_VERSION=1.6.0

RUN \
    echo "2016-03-08-0" > /dev/null && \
    export TERM=dumb && \
    export LANG='en_US.UTF-8' && \
    source /opt/local/bin/x-set-shell-fonts-env.sh && \
    echo -e "${FONT_INFO}[INFO] Updating package database${FONT_DEFAULT}" && \
    reflector --latest 100 --verbose --sort score --save /etc/pacman.d/mirrorlist && \
    sudo -u nobody yaourt -Syy && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Updated package database${FONT_DEFAULT}" && \
    REQUIRED_PACKAGES=("gcc-fortran" "atlas-lapack-base" ) && \
    echo -e "${FONT_INFO}[INFO] Installing required packages [${REQUIRED_PACKAGES[@]}]${FONT_DEFAULT}" && \
    sudo -u nobody yaourt -S --needed --noconfirm --noprogressbar "${REQUIRED_PACKAGES[@]}" && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed required packages [${REQUIRED_PACKAGES[@]}]${FONT_DEFAULT}" && \
    echo -e "${FONT_INFO}[INFO] Installing netlib-java=1.1.2${FONT_DEFAULT}" && \
    cd /tmp && \
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
    mv /tmp/netlib-java/native_system/xbuilds/linux-x86_64/target/netlib-native_system-linux-x86_64.so /usr/lib/libnetlib-native_system-linux-x86_64.so && \
    mv /tmp/netlib-java/native_ref/xbuilds/linux-x86_64/target/netlib-native_ref-linux-x86_64.so /usr/lib/libnetlib-native_ref-linux-x86_64.so && \
    ldconfig && \
    cd /tmp && \
    rm -rf /tmp/netlib-java && \
    echo -e "${FONT_INFO}[INFO] Installed netlib-java=1.1.2${FONT_DEFAULT}" && \
    echo -e "${FONT_INFO}[INFO] Installing spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    ([ -d /opt/local ] || mkdir -p /opt/local) && cd /opt/local && \
    cd /tmp && \
    curl --fail --silent --location "http://ftp.riken.jp/net/apache/spark/spark-${X_SPARK_VERSION}/spark-${X_SPARK_VERSION}.tgz" | tar xz && \
    cd spark-${X_SPARK_VERSION} && \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk ./make-distribution.sh --skip-java-test --with-tachyon --tgz -Pyarn -Phadoop-2.6 -Dhadoop.version=2.7.1 -Phive -Phive-thriftserver -Pnetlib-lgpl && \
    porg --log --package="spark-${X_SPARK_VERSION}" -- mv dist /opt/local/spark-${X_SPARK_VERSION} && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ mkdir /opt/local/spark-${X_SPARK_VERSION}/dist && \
    porg --log --package="spark-${X_SPARK_VERSION}" -+ mv spark-${X_SPARK_VERSION}*.tgz /opt/local/spark-${X_SPARK_VERSION}/dist/. && \
    cd /opt/local && \
    ln -sf spark-${X_SPARK_VERSION} spark && \
    echo -e "${FONT_SUCCESS}[SUCCESS] Installed spark-${X_SPARK_VERSION}${FONT_DEFAULT}" && \
    /opt/local/bin/x-archlinux-remove-unnecessary-files.sh && \
#    pacman-optimize && \
    rm -f /etc/machine-id

#    mvn -Pyarn -Phadoop-2.4 -Dhadoop.version=2.6.0 -Phive -Phive-thriftserver -DskipTests clean package && \
