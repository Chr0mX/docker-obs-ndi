FROM ubuntu:22.04

ARG DEBIAN_FRONTEND="noninteractive"

# for the VNC connection
EXPOSE 5900

# for the browser VNC client
EXPOSE 5901

# for the obs-websocket plugin
EXPOSE 4455

# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456

#Add needed nvidia environment variables for https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# Make sure the dependencies are met

RUN \
        apt-get update \
        && apt install -y tigervnc-standalone-server nano htop fluxbox avahi-daemon xterm git build-essential cmake curl ffmpeg git libboost-dev libnss3 mesa-utils qtbase5-dev strace x11-xserver-utils net-tools python3 python3-numpy scrot wget software-properties-common vlc jq intel-opencl-icd i965-va-driver-shaders intel-media-va-driver-non-free udev unrar qt5-image-formats-plugins \
        && sed -i 's/geteuid/getppid/' /usr/bin/vlc \
        && add-apt-repository ppa:obsproject/obs-studio \
        && git clone --branch v1.4.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
        && git clone --branch v0.11.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
        && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
        && ln -s /usr/bin/python3 /usr/bin/python \
        && mkdir -p /config/obs-studio /root/.config/
RUN \
        apt install -y obs-studio \
        && apt-get update \
        && apt-get clean -y \
        && apt-get dist-upgrade -y
RUN \
        wget -q -O /opt/container_startup.sh https://github.com/Chr0mX/docker-obs-ndi/raw/master/container_startup.sh \
        && wget -q -O /opt/x11vnc_entrypoint.sh https://github.com/Chr0mX/docker-obs-ndi/raw/master/x11vnc_entrypoint.sh \
        && mkdir -p /opt/startup_scripts \
        && wget -q -O /opt/startup_scripts/startup.sh https://github.com/Chr0mX/docker-obs-ndi/raw/master/startup_scripts/startup.sh \
        && wget -q -O /tmp/libndi5_5.5.3-1_amd64.deb https://github.com/obs-ndi/obs-ndi/releases/download/4.11.1/libndi5_5.5.3-1_amd64.deb \
        && wget -q -O /tmp/obs-ndi-4.11.1-linux-x86_64.deb https://github.com/obs-ndi/obs-ndi/releases/download/4.11.1/obs-ndi-4.11.1-linux-x86_64.deb \
# Download and install the plugins for NDI
        && dpkg -i /tmp/*.deb \
        && rm -rf /tmp/*.deb \
        && rm -rf /var/lib/apt/lists/* \
        && chmod +x /opt/*.sh \
        && chmod +x /opt/startup_scripts/*.sh

# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Screencast\" command=\"obs\"" >> /usr/share/menu/custom-docker \
        && echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
