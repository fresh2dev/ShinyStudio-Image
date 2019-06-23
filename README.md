# ShinyStudio

## *A Docker image of RStudio + VS Code + Shiny Server, driven by ShinyProxy.*

- [Overview](#Overview)
- [Repos](#Repos)
- [Setup from DockerHub](#Setup-from-DockerHub)
    - [Customization](#Customization)
- [Setup from GitHub](#Setup-from-GitHub)
- [Develop](#Develop)
- [Tools](#Tools)
- [Security](#Security)
- [Multiple Sites](#Multiple-Sites)
    - [Shared Content](#Shared-Content)
- [References](#References)

![](https://i.imgur.com/rtd29qCh.png)

![ShinyStudio](https://i.imgur.com/FIzE0d7.png)

## Overview

ShinyStudio is a Docker image which extends
[rocker/verse](https://hub.docker.com/r/rocker/verse) to include
RStudio, Shiny Server, VS Code, and ShinyProxy.

ShinyStudio leverages ShinyProxy to provide:

-   a centralized, pre-configured development environment.
-   a centralized repository for documents written in Markdown,
    RMarkdown, or HTML.
-   a simple and secure method for sharing web apps developed with
    RStudio Shiny.

![](https://i.imgur.com/ppQsjIx.png)

The ShinyStudio image consists of the products described below:

-   [ShinyProxy](https://www.shinyproxy.io/)
-   [Shiny Server](https://shiny.rstudio.com/)
-   [RStudio Server](https://www.rstudio.com/)
-   [VS Code](https://code.visualstudio.com/), modified by
    [Coder.com](https://coder.com/)

![](https://i.imgur.com/qc7bL1I.gif)

## Repos

The [GitHub repo for the ShinyStudio image](https://github.com/dm3ll3n/ShinyStudio-Image) is used to build the image published on DockerHub. The image is great for a personal instance, a quick demo, or the building blocks for a very customized setup.

https://github.com/dm3ll3n/ShinyStudio-Image

The [repo for the enhanced setup of ShinyStudio](https://github.com/dm3ll3n/ShinyStudio) builds upon the base image to provide an example of a more enterprise-ready instance of ShinyStudio, including NGINX, InfluxDB, and control scripts.

https://github.com/dm3ll3n/ShinyStudio

## Setup from DockerHub

> Setup must be run as a non-root user.

First, create a network named `shinystudio-net` to be shared by all
spawned containers.

``` text
docker network create shinystudio-net
```

Then, pull and run the ShinyStudio image directly from DockerHub.

``` text
docker run --rm -it --name shinyproxy \
    --network shinystudio-net \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e USERID=$USERID \
    -e USER=$USER \
    -e PASSWORD=password \
    -e MOUNTPOINT="${HOME}/ShinyStudio" \
    -e SITEID=default \
    -p 8080:8080 \
    dm3ll3n/shinystudio
```

Once complete, open a web browser and navigate to
`http://<hostname>:8080`. Log in with your username and the password
`password`.

Variables:

| **Variable** | **Default**           | **Explained**                                                                                   |
|--------------|-----------------------|-------------------------------------------------------------------------------------------------|
| USERID       | $USERID               | For proper permissions, this value should not be changed.                                       |
| USER         | $USER                 | Username to use at the ShinyProxy login screen.                                                 |
| PASSWORD     | password              | Password to use at the ShinyProxy login screen.                                                 |
| MOUNTPOINT   | "${HOME}/ShinyStudio" | The path to store site content and user settings.                                               |
| SITEID       | default               | Defines the folder name that this site’s content will reside in (`$MOUNTPOINT/sites/$SITEID`).  |
| ROOT         | false                 | Grant root permission in RStudio / VS Code? Useful for testing, but changes are not persistent. |

### Customization

Use bind-mounts to overwrite the default ShinyProxy config ([read more](https://www.shinyproxy.io/configuration/)), the default background, or default logo.

``` text
docker run --rm -it --name shinyproxy \
    --network shinystudio-net \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e USERID=$USERID \
    -e USER=$USER \
    -e PASSWORD=password \
    -e MOUNTPOINT="${HOME}/ShinyStudio" \
    -e SITEID=default \
    -p 8080:8080 \
    -v "${PWD}/application.yml:/opt/shinyproxy/application.yml"
    -v "${PWD}/imgs/background.png:/opt/shinyproxy/templates/grid_layout/assets/img/background.png" \
    -v "${PWD}/imgs/logo.png:/opt/shinyproxy/templates/grid_layout/assets/img/logo.png"
    dm3ll3n/shinystudio
```

## Setup from GitHub

The enhanced ShinyStudio setup requires Docker, docker-compose, and Git.

> Setup must be run as a non-root user.

``` text
# Clone the master branch.
git clone https://github.com/dm3ll3n/ShinyStudio

# Enter the new directory.
cd ShinyStudio

# Setup and run.
./control.sh setup
```

The default mountpoint is `$PWD/content`. To specify another mountpoint,
pass the desired path as an argument to the setup:

``` text
./control.sh setup "${HOME}/ShinyStudio"
```

Once complete, open a web browser and navigate to
`http://<hostname>:8080`.

The default logins are:

-   `user`: `user`
-   `admin`: `admin`
-   `superadmin`: `superadmin`

## Develop

Open your IDE of choice and notice two important directories:

-   \_\_ShinyStudio\_\_
-   \_\_Personal\_\_

> Files must be saved in either of these two directories in order to
> persist between sessions.

![](https://i.imgur.com/ac7iKDHh.png)

These two folders are shared between instances RStudio, VS Code, and
Shiny Server. So, creating new content is as simple as saving a file to
the appropriate directory.

![](https://i.imgur.com/lAuTMgBh.png)

## Tools

The ShinyStudio image comes with…

-   R
-   Python 3
-   PowerShell

…and ODBC drivers for:

-   SQL Server
-   PostgresSQL
-   Cloudera Impala.

These are persistent because they are built into the image.

|                             | Persistent |
|----------------------------:|:----------:|
| \_\_ShinyStudio__ directory |     Yes    |
|    \_\_Personal__ directory |     Yes    |
|           Other directories |   **No**   |
|                 R Libraries |     Yes    |
|             Python Packages |     Yes    |
|          PowerShell Modules |     Yes    |
|       RStudio User Settings |     Yes    |
|       VS Code User Settings |     Yes    |
|              Installed Apps |   **No**   |
|           Installed Drivers |   **No**   |

![](https://i.imgur.com/lgKdx93.png)

## References

-   <https://github.com/rocker-org/rocker-versioned/blob/master/rstudio/README.md>
-   <https://www.shinyproxy.io/>
-   <https://telethonkids.wordpress.com/2019/02/08/deploying-an-r-shiny-app-with-docker/>
-   <https://appsilon.com/alternatives-to-scaling-shiny>
