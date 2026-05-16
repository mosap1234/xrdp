FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/alpine
ENV DISPLAY=:1
ENV VNC_PORT=5901

# 1. تثبيت الواجهة، خادم الـ VNC، الكروميوم، وأدوات النظام الأساسية
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    chromium \
    sudo \
    curl \
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# 2. إنشاء مستخدم حقيقي (alpine) لحل مشاكل الأمان وتشغيل الكروميوم
RUN useradd -m -s /bin/bash alpine && \
    echo "alpine:alpine" | chpasswd && \
    adduser alpine sudo && \
    echo "alpine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 3. إعداد ملفات تشغيل الواجهة وكلمة المرور للمستخدم الجديد
USER alpine
WORKDIR $HOME

RUN mkdir -p $HOME/.vnc $HOME/Desktop && \
    echo "#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nstartxfce4 &" > $HOME/.vnc/xstartup && \
    chmod +x $HOME/.vnc/xstartup

# تعيين كلمة المرور لتطبيق الـ VNC الخارجي لتكون (alpine)
RUN echo "alpine" | vncpasswd -f > $HOME/.vnc/passwd && chmod 600 $HOME/.vnc/passwd

# ضبط إعدادات الكروميوم ليعمل بسلاسة داخل الحاوية
RUN echo "export CHROMIUM_FLAGS='--no-sandbox --disable-dev-shm-usage'" >> $HOME/.bashrc

EXPOSE $VNC_PORT

# 4. أمر التشغيل الذكي: ينظف الكاش القديم، يشغل الـ DBus، ويطلق السيرفر بشكل دائم
CMD ["sh", "-c", "sudo rm -f /tmp/.X1-lock /tmp/.X11-unix/X1; vncserver :1 -geometry 1280x720 -depth 24 -rfbauth $HOME/.vnc/passwd -localhost no -forever && tail -f $HOME/.vnc/*.log"]
