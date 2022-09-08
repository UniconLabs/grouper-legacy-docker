# README

## Introduction

This Docker build creates older versions of Grouper, which were released before Grouper was distributed as an OCI image. Why would you want this? The most likely reason would be
that you are currently on an older Grouper version, and want to set up a simulation of your install to test upgrade paths. These images are also useful for historical references. As time
and technology moves forward, it will become more difficult to set up these versions without workarounds. For example, version 2.2.x was originally installed with Tomcat 6; however, Tomcat 6 is no
longer compatible with newer versions of Java 8.

The original standalone installer jar would download a number of distribution files for Tomcat, Ant, Grouper artifacts, and patch bundles. To save time in building, these files have all been
downloaded and mounted in a build container, so the installer can do an offline build.

This image uses Amazon Corretto Java 8, similar to official Grouper images. There was no compelling reason for that other than to match standard Grouper, and openjdk would have also worked.

In its current form, it doesn't use a build container. It does clean up the unpacked distro files, but there could be other extraneous files included in the image. It also keeps the installed directory names in their default locations; e.g. /opt/grouper.apiBinary-2.2.2 or /opt/grouper.ui-2.2.2. Depending on the customer, this may match more closely with their installation, compared to a cleaner image with the runtime directories renamed and organized.


## Building an image

```
docker build -t grouper-legacy:2.2.2 .
```

## Starting a container

### Configuring Grouper properties

- grouper.hibernate.properties: Set the hibernate.connection url, username, and password values.
- morphString.properties: Optional in 2.2.2, and no need to modify
- sources.xml: Grouper 2.2.2 is still optionally using sources.xml instead of subject properties. The format is not well documented in the Grouper wiki, but there are LDAP and other examples in the Git `subject/conf` directory. Version 2.2.2 was the last version using this subject submodule for builds. Thus, this directory may be deleted at some point. if it's gone, check out Git tag GROUPER_2_2_2 to retrieve it.

You can mount all these directly to `/opt/grouper.ui-${VERSION}/dist/grouper/WEB-INF/classes/`.


### Initializing an external database

This requires you have an external database that the Grouper container is able to connect to. Before running the UI/WS container, run the container with the `initdb` command, which will run `bin/gsh.sh -registry -runscript -noprompt` (which sets up the database) and exit. Alternatively,
set environment variable GROUPER_INITDB=y, which will also run the gsh initialization, then afterward run any container command (or the UI/WS if none passed).


### Running the quickstart database

The image includes an embedded HSQL database, already initialized with the Grouper data, and sample data added in. To start it before running another command, run the container with environment option `STARTQS=y`. Since the default grouper.hibernate.properties file is already set up to access this database, nothing more needs to configured. For example, the command below will start the quickstart database, then run the UI/WS.

```
docker run --rm -p 9001:9001 -p 8080:8080 -e GROUPER_STARTQS=y grouper-legacy:2.2.2
```

### Running UI/WS

This is the default image command, so just start up a a new container (with custom property files mounted). This is configured to run both /grouper and /grouper-ws contexts.

If using the built-in quickstart database, you may want to open port 9001:9001 if you need database access.

If you want to remote debug, add environment `CATALINA_OPTS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005`, and port mapping `-p 8000:5005`.

The default access to the UI and WS is using Basic Authentication, with login GrouperSystem/GrouperSystem. This is set in build file `files/patch/tomcat/tomcat-users.xml.patch`.


## Notes for workarounds

- The Apache Tomcat 6.0.35 installed with Grouper 2.2.2 does not work with recent Java 8 versions (https://stackoverflow.com/a/38444118). Hitting a jsp page returns a stacktrace as below. The workaround is to use Tomcat 7, which requires its own workaround below

```
org.apache.jasper.compiler.JDTCompiler$1 findType
SEVERE: Compilation error
org.eclipse.jdt.internal.compiler.classfmt.ClassFormatException
	at org.eclipse.jdt.internal.compiler.classfmt.ClassFileReader.<init>(ClassFileReader.java:372)
	at org.apache.jasper.compiler.JDTCompiler$1.findType(JDTCompiler.java:206)
	at org.apache.jasper.compiler.JDTCompiler$1.findType(JDTCompiler.java:163)
    ...
```

- In Tomcat 7, URLs to a bare directory no longer redirect to the slash-appended version by default. This causes the chain of redirects ending up in `/grouperUi` to have a CSRF error, since the CSRF properties only allow unprotected access to `/grouperUi/` and not `/grouperUi`. One solution is to add a CSRF override for `/grouperUi`. Another is to modify index.jsp to redirect to `/grouperUi`. This Docker build uses a third option which is to add back the Tomcat default to redirect bare directories to add the slash. This was selected because it's unknown what other pages besides `grouperUi` would break with the change in default behavior.

- The postgres jdbc jar includes with 2.2.2 does not work with recent Postgres versions. If using postgres, mount a current version to /opt/grouper.ui-${VERSION}/dist/grouper/WEB-INF/lib/postgresql.jar.

- Grouper 2.2.2 was meant to run under Java 1.7, and the default installer even aborts when it detects Java 8. Installer property `grouperInstaller.autorun.wrongJavaContinue` was set to true work around this.



## NOTES


### importing quickstart data manually

Users:

```
gsh -registry -runsqlfile /opt/subjects.sql -noprompt
```

Groups:

```
gsh -xmlimportold GrouperSystem /opt/quickstart.xml -noprompt
```


### where are the files?

UI webapp base is /opt/grouper.ui-2.2.2/dist/grouper

WS webapp is /opt/grouper.ws-2.2.2/grouper-ws/build/dist/grouper-ws

Tomcat config is in /opt/apache-tomcat-7.0.99/conf/server.xml (which defines the /grouper and /grouper-ws contexts)

Tomcat logs are in /opt/apache-tomcat-7.0.99/logs

Grouper logs from gsh will be in /opt/grouper.apiBinary-2.2.2/logs/grouper_error.log

Grouper logs from UI will be in /var/log/grouper/grouper_error.log
