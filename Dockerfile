FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# تثبيت الحزم الأساسية
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies tigervnc-standalone-server tigervnc-common tigervnc-tools sudo xterm \
    init systemd snapd vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps

# تثبيت فايرفوكس
RUN apt install software-properties-common -y && \
    add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox && \
    apt update -y && apt install -y firefox xubuntu-icon-theme

# إعداد مجلد VNC والباسورد للمستخدم root
RUN mkdir -p /root/.vnc && \
    echo "mosap@123123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# إعداد ملف التشغيل (xstartup) واجهة xfce4
RUN echo '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xrdb $HOME/.Xresources\n\
exec startxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# فتح بورت VNC الأساسي
EXPOSE 5901

# التعديل هنا: أضفنا sleep 2 عشان نضمن إنشاء الملف قبل الـ tail وما يعلق الحاوية
CMD bash -c "rm -rf /tmp/.X* /tmp/.X11-unix && vncserver :1 -geometry 1024x768 -depth 24 -localhost no && sleep 2 && tail -f /root/.vnc/*.log"
