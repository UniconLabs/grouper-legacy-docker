FROM amazoncorretto:8

EXPOSE 8080 8443 5005 9001

RUN yum install -y gzip tar procps dos2unix nano less patch && yum clean all

# RUN wget https://software.internet2.edu/grouper/release/2.2.2/grouper.installer-2.2.2.tar.gz
# RUN wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.99/bin/apache-tomcat-7.0.99.tar.gz

COPY files/install /var/archive
COPY files/grouper-dl /opt
COPY files/patch /tmp/patch
COPY files/bin /usr/local/bin

# The Grouper-installed tomcat 6 is not compatible with jdk8u91+
#   "The type java.io.ObjectInputStream cannot be resolved. It is indirectly referenced from required .class files"
RUN cd /opt && tar xzf /var/archive/apache-tomcat-7.0.99.tar.gz

RUN mkdir /var/log/grouper && cd /opt && tar xzf /var/archive/grouper.installer-2.2.2.tar.gz && cp -p /var/archive/grouper.installer.properties /opt/grouper.installer-2.2.2/

RUN java -cp /opt/grouper.installer-2.2.2:/opt/grouper.installer-2.2.2/grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller \
    && rm /opt/*.gz /opt/*.tar \
    && rm -rf /opt/apache-tomcat-6.0.35 /opt/grouper_v2_2_2_*_patch_* \
    && chmod a+rx /opt/grouper.ui-2.2.2/dist/grouper/WEB-INF/bin/gsh.sh

RUN patch /opt/apache-tomcat-7.0.99/conf/server.xml < /tmp/patch/tomcat/server.xml.patch \
    && patch /opt/apache-tomcat-7.0.99/conf/tomcat-users.xml < /tmp/patch/tomcat/tomcat-users.xml.patch \
    && patch /opt/apache-tomcat-7.0.99/conf/context.xml < /tmp/patch/tomcat/context.xml.patch


WORKDIR /opt/grouper.ui-2.2.2/dist/grouper/WEB-INF

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/opt/apache-tomcat-7.0.99/bin/catalina.sh", "run"]
