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
# rmarkdown 1.12 does not display floating TOC; downgrade to 1.11.
RUN R -e "install.packages(c('reticulate', 'png', 'DBI', 'odbc', 'shinydashboard', 'flexdashboard', 'shinycssloaders', 'DT', 'visNetwork', 'networkD3'))" && \
    R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/rmarkdown/rmarkdown_1.11.tar.gz', repos=NULL)"

COPY samples /srv/shiny-server
RUN mkdir -p /srv/shiny-server/_apps && \
    git clone https://github.com/dm3ll3n/Shiny-GEM /srv/shiny-server/_apps/Shiny-GEM && \
    Rscript '/srv/shiny-server/_apps/Shiny-GEM/install-requirements.R' && \
    chmod -R 777 /r-libs

# setup python
ENV VIRTUAL_ENV /pyenv
RUN apt-get update && \
    apt-get install -y python3-pip python3-venv libpython-dev libpython3-dev python-dev python3-dev && \
    python3 -m venv "${VIRTUAL_ENV}" && \
    chmod -R 777 "${VIRTUAL_ENV}" && \
    "${VIRTUAL_ENV}/bin/activate"

# install python packages
ENV PATH "${VIRTUAL_ENV}/bin:${PATH}"
RUN echo "export PATH=\"${VIRTUAL_ENV}/bin:\${PATH}\"" >> /etc/profile && \
    pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip && \
    pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org wheel && \
    pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org \
        Cython numpy matplotlib pandas tqdm ezpq paramiko requests pylint jupyter && \
    apt-get install -y python3-tk && \
    pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org plotnine

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

# install kerberos
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

# copy custom start command and make it executable.
COPY configs/start.sh /start.sh
RUN chmod +x /start.sh

CMD [ "/start.sh", "shinyproxy" ]
