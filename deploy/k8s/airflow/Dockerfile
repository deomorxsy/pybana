FROM apache/airflow:3.0.2
# debian-based

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# USER airflow

WORKDIR /app/
COPY ./deploy/k8s/airflow/requirements.txt .
ENV AFW_USER afw

RUN <<EOF

# create user and group
setup() {


mkdir -p /app/
ls -allhtr /app/


# Check if the group already exists, if not, create it
getent group "${AFW_USER}" > /dev/null || addgroup --gid 1000 "${AFW_USER}"

AFW_GID=$(getent group "${AFW_USER}" | cut -d: -f3)

getent passwd "${AFW_USER}" > /dev/null || \
adduser --shell /bin/bash \
    --uid 1000 \
    --gid "${AFW_GID}" \
    --gecos "" \
    --disabled-password \
    --home "/home/${AFW_USER}" \
    "${AFW_USER}"

mkdir -p /home/${AFW_USER}/app/ &&  \

chown -R $AFW_USER:$AFW_USER /home/${AFW_USER}/app/ && \
cp /app/requirements.txt /home/${AFW_USER}/app/ &&

cd /home/${AFW_USER}/app/ || return && \

# Copy files to /test beforehand



su "${AFW_USER}" -c '

export PATH=$HOME/.local/bin/:$PATH && \
pip3 install --user --upgrade pip virtualenv --break-system-packages && \
virtualenv "$HOME"/app/afw-custom && source ./afw-custom/bin/activate && \

# create and change dir to install virtualenv
pip3 install --user --upgrade pip virtualenv --break-system-packages && \

# source and activate venv
virtualenv venv && source ./venv/bin/activate && \
python3 -m ensurepip --default-pip && \

#copy the requirements file
cp /app/requirements.txt .
pip3 install --no-cache-dir -r ./requirements.txt && \

deactivate
'
}
setup

EOF
