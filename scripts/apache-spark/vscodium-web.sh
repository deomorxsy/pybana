#!/bin/sh

podman run -d \
  --name=vscodium \
  --cap-add=IPC_LOCK \
  --security-opt seccomp=unconfined \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 3000:3000 \
  -p 3001:3001 \
  --shm-size="1gb" \
  --restart unless-stopped \
  lscr.io/linuxserver/vscodium:latest \

  #-v /path/to/vscodium/config:/config \
  # --shm-size="1gb" \
  # --restart unless-stopped \
  # lscr.io/linuxserver/vscodium:latest
