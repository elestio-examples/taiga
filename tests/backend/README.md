<a href="https://elest.io">
  <img src="https://elest.io/images/elestio.svg" alt="elest.io" width="150" height="75">
</a>

[![Discord](https://img.shields.io/static/v1.svg?logo=discord&color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=Discord&message=community)](https://discord.gg/4T4JGaMYrD "Get instant assistance and engage in live discussions with both the community and team through our chat feature.")
[![Elestio examples](https://img.shields.io/static/v1.svg?logo=github&color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=github&message=open%20source)](https://github.com/elestio-examples "Access the source code for all our repositories by viewing them.")
[![Blog](https://img.shields.io/static/v1.svg?color=f78A38&labelColor=083468&logoColor=ffffff&style=for-the-badge&label=elest.io&message=Blog)](https://blog.elest.io "Latest news about elestio, open source software, and DevOps techniques.")

# Taiga, verified and packaged by Elestio

[Taiga](https://github.com/taigaio/taiga) is a free and open-source project management tool for cross-functional agile teams to work effectively.

<img src="https://github.com/elestio-examples/taiga/raw/main/taiga.jpg" alt="taiga" width="800">

Deploy a <a target="_blank" href="https://elest.io/open-source/taiga">fully managed taiga</a> on <a target="_blank" href="https://elest.io/">elest.io</a> if you want automated backups, reverse proxy with SSL termination, firewall, automated OS & Software updates, and a team of Linux experts and open source enthusiasts to ensure your services are always safe, and functional.

[![deploy](https://github.com/elestio-examples/taiga/raw/main/deploy-on-elestio.png)](https://dash.elest.io/deploy?source=cicd&social=dockerCompose&url=https://github.com/elestio-examples/taiga)

# Why use Elestio images?

- Elestio stays in sync with updates from the original source and quickly releases new versions of this image through our automated processes.
- Elestio images provide timely access to the most recent bug fixes and features.
- Our team performs quality control checks to ensure the products we release meet our high standards.

# Usage

## Git clone

You can deploy it easily with the following command:

    git clone https://github.com/elestio-examples/taiga.git

Copy the .env file from tests folder to the project directory

    cp ./tests/.env ./.env

Edit the .env file with your own values.

Create data folders with correct permissions

    mkdir -p ./data 
    chown -R 1001:1001 ./data

Run the project with the following command

    docker-compose up -d

You can access the Web UI at: `http://your-domain:9000`

## Docker-compose

Here are some example snippets to help you get started creating a container.

    version: "3.5"

    x-environment:
        &default-back-environment
        # Database settings
        POSTGRES_DB: taiga
        POSTGRES_USER: taiga
        POSTGRES_PASSWORD: ${APP_PASSWORD}
        POSTGRES_HOST: taiga-db
        # Taiga settings
        TAIGA_SECRET_KEY: ${APP_PASSWORD}
        TAIGA_SITES_SCHEME: "https"
        TAIGA_SITES_DOMAIN: ${DOMAIN}
        TAIGA_SUBPATH: "" # "" or "/subpath"
        # Email settings. Uncomment following lines and configure your SMTP server
        EMAIL_BACKEND: "django.core.mail.backends.smtp.EmailBackend"
        DEFAULT_FROM_EMAIL: ${SMTP_FROM_EMAIL}
        EMAIL_USE_TLS: "False"
        EMAIL_USE_SSL: "False"
        EMAIL_HOST: ${SMTP_HOST}
        EMAIL_PORT: ${SMTP_PORT}
        EMAIL_HOST_USER: ""
        EMAIL_HOST_PASSWORD: ""
        # Rabbitmq settings
        # Should be the same as in taiga-async-rabbitmq and taiga-events-rabbitmq
        RABBITMQ_USER: taiga
        RABBITMQ_PASS: ${APP_PASSWORD}
        # Telemetry settings
        PUBLIC_REGISTER_ENABLED: "True"
        ENABLE_TELEMETRY: "True"
        TAIGA_TELEMETRY_REFERER: "elest.io"

    x-volumes:
        &default-back-volumes
            - ./taiga-static-data:/taiga-back/static
            - ./taiga-media-data:/taiga-back/media
            # - ./config.py:/taiga-back/settings/config.py


    services:
        taiga-db:
            image: postgres:12.3
            environment:
                POSTGRES_DB: taiga
                POSTGRES_USER: taiga
                POSTGRES_PASSWORD: ${APP_PASSWORD}
            volumes:
                - ./taiga-db-data:/var/lib/postgresql/data
            networks:
                - taiga

        taiga-back:
            image: taigaio/taiga-back:${SOFTWARE_VERSION_TAG}
            environment: *default-back-environment
            volumes: *default-back-volumes
            networks:
                - taiga
            depends_on:
                - taiga-db
                - taiga-events-rabbitmq
                - taiga-async-rabbitmq

        taiga-async:
            image: taigaio/taiga-back:${SOFTWARE_VERSION_TAG}
            entrypoint: ["/taiga-back/docker/async_entrypoint.sh"]
            environment: *default-back-environment
            volumes: *default-back-volumes
            networks:
                - taiga
            depends_on:
                - taiga-db
                - taiga-back
                - taiga-async-rabbitmq

        taiga-async-rabbitmq:
            image: rabbitmq:3.8-management-alpine
            environment:
                RABBITMQ_ERLANG_COOKIE: secret-erlang-cookie
                RABBITMQ_DEFAULT_USER: taiga
                RABBITMQ_DEFAULT_PASS: ${APP_PASSWORD}
                RABBITMQ_DEFAULT_VHOST: taiga
            volumes:
                - ./taiga-async-rabbitmq-data:/var/lib/rabbitmq
            networks:
                - taiga

        taiga-front:
            image: taigaio/taiga-front:${SOFTWARE_VERSION_TAG}
            environment:
                TAIGA_URL: ${BASE_URL}
                TAIGA_WEBSOCKETS_URL: "wss://${DOMAIN}"
                TAIGA_SUBPATH: "" # "" or "/subpath"
                PUBLIC_REGISTER_ENABLED: "true"
            networks:
                - taiga
            # volumes:
            #   - ./conf.json:/usr/share/nginx/html/conf.json

        taiga-events:
            image: taigaio/taiga-events:${SOFTWARE_VERSION_TAG}
            environment:
                RABBITMQ_USER: taiga
                RABBITMQ_PASS: ${APP_PASSWORD}
                TAIGA_SECRET_KEY: ${APP_PASSWORD}
            networks:
                - taiga
            depends_on:
                - taiga-events-rabbitmq

        taiga-events-rabbitmq:
            image: rabbitmq:3.8-management-alpine
            environment:
                RABBITMQ_ERLANG_COOKIE: secret-erlang-cookie
                RABBITMQ_DEFAULT_USER: taiga
                RABBITMQ_DEFAULT_PASS: ${APP_PASSWORD}
                RABBITMQ_DEFAULT_VHOST: taiga
            volumes:
                - ./taiga-events-rabbitmq-data:/var/lib/rabbitmq
            networks:
                - taiga

        taiga-protected:
            image: taigaio/taiga-protected:${SOFTWARE_VERSION_TAG}
            environment:
                MAX_AGE: 360
                SECRET_KEY: ${APP_PASSWORD}
            networks:
                - taiga

        taiga-gateway:
            image: nginx:1.19-alpine
            ports:
                - "172.17.0.1:9000:80"
            volumes:
                - ./taiga-gateway/taiga.conf:/etc/nginx/conf.d/default.conf
                - ./taiga-static-data:/taiga/static
                - ./taiga-media-data:/taiga/media
            networks:
                - taiga
            depends_on:
                - taiga-front
                - taiga-back
                - taiga-events


    networks:
        taiga:


# Maintenance

## Logging

The Elestio taiga Docker image sends the container logs to stdout. To view the logs, you can use the following command:

    docker-compose logs -f

To stop the stack you can use the following command:

    docker-compose down

## Backup and Restore with Docker Compose

To make backup and restore operations easier, we are using folder volume mounts. You can simply stop your stack with docker-compose down, then backup all the files and subfolders in the folder near the docker-compose.yml file.

Creating a ZIP Archive
For example, if you want to create a ZIP archive, navigate to the folder where you have your docker-compose.yml file and use this command:

    zip -r myarchive.zip .

Restoring from ZIP Archive
To restore from a ZIP archive, unzip the archive into the original folder using the following command:

    unzip myarchive.zip -d /path/to/original/folder

Starting Your Stack
Once your backup is complete, you can start your stack again with the following command:

    docker-compose up -d

That's it! With these simple steps, you can easily backup and restore your data volumes using Docker Compose.

# Links

- <a target="_blank" href="https://github.com/taigaio/taiga">taiga Github repository</a>

- <a target="_blank" href="https://docs.taiga.io/">taiga documentation</a>

- <a target="_blank" href="https://github.com/elestio-examples/taiga">Elestio/taiga Github repository</a>
