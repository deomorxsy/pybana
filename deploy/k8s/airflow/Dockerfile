FROM apache/airflow:2.10.4

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow

WORKDIR /app/
COPY requirements.txt .
ENV USER USER

RUN <<EOF
# create user and group
addgroup -g 1000 -S "${USER}" && \
adduser -s /bin/sh -u 1000 -G "${USER}" \
    -h "/home/${USER}" -D "${USER}" && \
su "${USER}" && \

# create and change dir to install virtualenv
mkdir -p "/home/${USER}/airflow-config" && \
cd "$/home/{USER}/airflow-config/" && \
pip3 install --user --upgrade pip virtualenv --break-system-packages && \
export PATH=$HOME/.local/bin/:$PATH && \

# source and activate venv
virtualenv venv && source ./venv/bin/activate && \
python3 -m ensurepip --default-pip && \

#copy the requirements file
cp /app/requirements.txt .
pip3 install --no-cache-dir -r ./requirements.txt && \

# don't forget
deactivate


EOF
