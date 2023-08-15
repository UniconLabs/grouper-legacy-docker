FROM amazoncorretto:8

EXPOSE 8080 8443 5005 9001

RUN yum install -y gzip tar procps dos2unix nano less patch && yum clean all

# RUN wget https://software.internet2.edu/grouper/release/2.3.0/grouper.installer-2.3.0.tar.gz

COPY files/install /var/archive
COPY files/grouper-dl /var/archive/grouper-dl
COPY files/opt /opt
COPY files/bin /usr/local/bin

RUN mkdir /var/log/grouper && cd /opt && tar xzf /var/archive/grouper.installer-2.3.0.tar.gz && cp -p /var/archive/grouper.installer.properties /opt/grouper.installer-2.3.0/

RUN java -cp /opt/grouper.installer-2.3.0:/opt/grouper.installer-2.3.0/grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller

RUN rm /var/archive/grouper-dl/*.gz /var/archive/grouper-dl/*.tar \
    && rm -rf /var/archive/grouper-dl/patches/grouper_v2_3_0_*_patch_* \
    && chmod a+rx /opt/grouper.ui-2.3.0/dist/grouper/WEB-INF/bin/gsh.sh


WORKDIR /opt/grouper.ui-2.3.0/dist/grouper/WEB-INF

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/opt/apache-tomcat-8.5.12/bin/catalina.sh", "run"]
