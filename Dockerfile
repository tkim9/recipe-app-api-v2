# name of the docker image: name of the tag/version
# alpine is very light weight linux
FROM python:3.9-alpine3.13 
LABEL maintainer="tkim"

# when you don't want to buffer the output from python
# logs will display immediately to the screen
ENV PYTHONUNBUFFERED 1

# operation inside container
# expose port
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
WORKDIR /app
EXPOSE 8000  

# this arg gets overwritten by docker-compose
ARG DEV=false

# if we run this line by line, it creates separate layers within container
# so we want to avoid that to keep it light weight
# you should remove files that you don't need after it is built
# always adduser, and not use root user
# if your application is compromised, attacker only has access to that user
# if DEV, then it will install dev requirements including linting
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --udpate --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# add py/bin to system path
ENV PATH="/py/bin:$PATH"

# everything above this line is done with root user
# and then switch to non-root user
USER django-user

