FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. تثبيت الواجهة، الخادم، الكروميوم، وأدوات الصوت مباشرة من المتجر المستقر
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    xorgxrdp \
    chromium \
    pulseaudio \
    pavucontrol \
    dbus-x11 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 2. إعداد المستخدم الافتراضي (alpine) وبكلمة مرور (alpine) كما في ملفك تماماً
RUN adduser --disabled-password --gecos "" alpine \
    && echo "alpine:alpine" | chpasswd \
    && adduser alpine sudo

# 3. توجيه الواجهة الرسومية للمستخدم عند الاتصال
RUN echo "startxfce4" > /home/alpine/.xsession \
    && chown alpine:alpine /home/alpine/.xsession

# 4. إعدادات الخادم ليعمل في الواجهة ويرسل السجلات لـ Railway
RUN sed -i 's/fork=yes/fork=no/g' /etc/xrdp/xrdp.ini \
    && adduser xrdp ssl-cert

# فتح منفذ الـ RDP القياسي
EXPOSE 3389

# 5. أمر التشغيل السحري الذي يشغل الـ dbus والـ xrdp معاً دون الحاجة لسكربتات خارجية
CMD ["sh", "-c", "service dbus start && service xrdp start && tail -f /var/log/xrdp.log"]
