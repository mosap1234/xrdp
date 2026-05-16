FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. تثبيت الواجهة، الكروميوم، أدوات الصوت، وأدوات تحويل الشاشة لمتصفح (noVNC)
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    chromium \
    pulseaudio \
    pavucontrol \
    dbus-x11 \
    sudo \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    && rm -rf /var/lib/apt/lists/*

# 2. إعداد المستخدم الافتراضي (alpine) وبكلمة مرور (alpine)
RUN adduser --disabled-password --gecos "" alpine \
    && echo "alpine:alpine" | chpasswd \
    && adduser alpine sudo

# 3. إعداد بيئة الشاشة الوهمية للمتصفح
ENV DISPLAY=:1
ENV RESOLUTION=1280x720x24

# فتح منفذ الويب الافتراضي (بدل الـ RDP المعقد)
EXPOSE 8080

# 4. أمر التشغيل السحري: يشغل شاشة وهمية، يفتح الواجهة، ويرسلها للمتصفح فوراً برابط مباشر!
CMD ["sh", "-c", "service dbus start && Xvfb $DISPLAY -screen 0 $RESOLUTION & sleep 2 && xfsettingsd --display=$DISPLAY & startxfce4 & x11vnc -display $DISPLAY -nopw -listen localhost -forever & websockify --web /usr/share/novnc 8080 localhost:5900"]
