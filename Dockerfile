FROM rocker/verse:3.6.1

LABEL maintainer="dm3ll3n@gmail.com"

# essential vars
ENV DISABLE_AUTH true
ENV R_LIBS_USER /r-libs
ENV APPLICATION_LOGS_TO_STDOUT false

# add shiny immediately and expose port 3838.
RUN export ADD=shiny && bash /etc/cont-init.d/add

RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    apt-get install -y curl nano

# install Java 8 and ShinyProxy
RUN apt-get install -y openjdk-8-jdk-headless && \
    mkdir -p /opt/shinyproxy && \
    wget https://www.shinyproxy.io/downloads/shinyproxy-2.3.0.jar -O /opt/shinyproxy/shinyproxy.jar

COPY configs/shinyproxy/grid-layout /opt/shinyproxy/templates/grid-layout
COPY configs/shinyproxy/application.yml /opt/shinyproxy/application.yml

# create shared /r-libs directory and ensure it's writeable by all.
RUN mkdir /r-libs && \
    echo ".libPaths( c( '/r-libs', .libPaths() ) )" >> /usr/local/lib/R/etc/Rprofile.site

# install R packages
RUN R -e "install.packages(c('reticulate', 'DBI', 'odbc'))" && \
    chmod -R 777 /r-libs

COPY samples /srv/shiny-server

# setup python with miniconda.
RUN wget -nv https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /conda3 && \
    /conda3/bin/conda create -y -n py3 python=3.7 && \
    chmod -R 777 /conda3 && \
    /conda3/bin/conda install -y --name py3 jupyter

# set path
ENV PATH "/conda3/bin:${PATH}"
RUN echo "export PATH=\"/conda3/bin:\${PATH}\"" >> /etc/profile && \
    echo ". activate py3" >> /etc/profile

# install pwsh
# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux
RUN apt-get install -y libc6 libgcc1 libgssapi-krb5-2 liblttng-ust0 libstdc++6 libcurl3 libunwind8 libuuid1 zlib1g libssl1.0.2 libicu57 && \
    wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell_6.2.3-1.debian.9_amd64.deb -O /tmp/pwsh.deb && \
    dpkg -i /tmp/pwsh.deb && \
    rm -f /tmp/pwsh.deb && \
    pwsh -c "Install-Module SqlServer -Force"

# install VS code-server
RUN wget https://github.com/cdr/code-server/releases/download/2.1478-vsc1.38.1/code-server2.1478-vsc1.38.1-linux-x86_64.tar.gz -O /tmp/vs-code-server.tar.gz && \
    mkdir /tmp/vs-code-server && \
    tar -xzf /tmp/vs-code-server.tar.gz --strip 1 --directory /tmp/vs-code-server && \
    mv -f /tmp/vs-code-server/code-server /usr/local/bin/code-server && \
    rm -rf /tmp/vs-code-server.tar.gz && \
    mkdir /code-server-template && \
    code-server --user-data-dir /code-server-template --install-extension ms-python.python && \
    code-server --user-data-dir /code-server-template --install-extension ms-vscode.powershell && \
#     code-server --user-data-dir /code-server-template --install-extension ms-mssql.mssql && \
    code-server --user-data-dir /code-server-template --install-extension yzhang.markdown-all-in-one && \
    echo '#!/usr/bin/env bash' > '/setup_vscode.sh' && \
    echo 'cp -Rn /code-server-template/* ~/.local/share/code-server' >> '/setup_vscode.sh' && \
    chmod 555 '/setup_vscode.sh' && \
    # unsure why this is necessary, but it solves a fatal 'file not found' error.
    mkdir -p /src/packages/server/build/web && \
    echo '' > /src/packages/server/build/web/index.html

COPY configs/vscode/User/settings.json /code-server-template/User/settings.json
COPY configs/vscode/User/snippets /code-server-template/User/snippets

# install cronicle.
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash && \
    apt-get install -y nodejs && \
    mkdir -p /opt/cronicle && \
    cd /opt/cronicle && \
    curl -L https://github.com/jhuckaby/Cronicle/archive/v0.8.32.tar.gz | tar zxvf - --strip-components 1 && \
    npm install && \
    node bin/build.js dist
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y krb5-user

# install SQL Server odbc driver
RUN apt-get install -y unixodbc && \
    wget https://packages.microsoft.com/debian/9/prod/pool/main/m/msodbcsql17/msodbcsql17_17.3.1.1-1_amd64.deb -O /tmp/msodbcsql.deb && \
    ACCEPT_EULA=Y dpkg -i /tmp/msodbcsql.deb && \
    rm -f /tmp/msodbcsql.deb

# install PostgreSQL odbc driver
RUN apt-get install -y odbc-postgresql

# install cloudera odbc driver
RUN wget https://downloads.cloudera.com/connectors/ClouderaImpala_ODBC_2.6.2.1002/Debian/clouderaimpalaodbc_2.6.2.1002-2_amd64.deb -O /tmp/clouderaimpalaodbc_amd64.deb && \
    dpkg -i /tmp/clouderaimpalaodbc_amd64.deb && \
    rm -f /tmp/clouderaimpalaodbc_amd64.deb

# custom configs
COPY configs/rstudio/rserver.conf /etc/rstudio/rserver_custom.conf

COPY configs/odbc/odbcinst.ini /etc/odbcinst.ini
COPY configs/odbc/odbc.ini /etc/odbc.ini

COPY configs/krb/krb5.conf /etc/krb5.conf
ENV KRB5_CONFIG /etc/krb5.conf

# copy custom run commands.
COPY configs/rstudio/run /etc/services.d/rstudio/run
COPY configs/vscode/run /etc/services.d/vscode/run
COPY configs/shinyproxy/run /etc/services.d/shinyproxy/run
COPY configs/cronicle/run /etc/services.d/cronicle/run

# copy custom start command and make it executable.
COPY configs/start.sh /start.sh
RUN chmod +x /start.sh

CMD [ "/start.sh", "shinyproxy" ]
