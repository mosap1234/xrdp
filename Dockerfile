FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# 1. تثبيت الواجهة + xRDP والأدوات الأساسية
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies \
    xrdp xorgxrdp \
    sudo dbus-x11 x11-xserver-utils net-tools curl wget git tzdata \
    ca-certificates apt-transport-https software-properties-common gnupg2 unzip

# 2. تثبيت ثيم وأيقونات ويندوز 11 الرسمية
RUN git clone --depth 1 https://github.com/vinceliuice/Win11-gtk-theme.git /tmp/win11-theme && \
    /tmp/win11-theme/install.sh -d /usr/share/themes && \
    rm -rf /tmp/win11-theme && \
    git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/fluent-icons && \
    /tmp/fluent-icons/install.sh -d /usr/share/icons && \
    rm -rf /tmp/fluent-icons

# 3. خلفية ويندوز 11 المظلمة
RUN mkdir -p /usr/share/backgrounds/xfce && \
    curl -sSL -o /usr/share/backgrounds/xfce/xfce-blue.jpg https://raw.githubusercontent.com/alvatip/Windows11-Wallpapers/main/Dark/img0.jpg

# 4. تثبيت Google Chrome
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt update -y && apt install --no-install-recommends -y google-chrome-stable

# 5. تثبيت Visual Studio Code
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt update -y && apt install --no-install-recommends -y code

# 6. تعديل اختصارات التشغيل لتعمل بصلاحية الـ Root بأمان
RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable %U/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox --user-data-dir=\/root\/.config\/google-chrome %U/g' /usr/share/applications/google-chrome.desktop || true && \
    sed -i 's/Exec=\/usr\/share\/code\/code/Exec=\/usr\/share\/code\/code --no-sandbox --user-data-dir=\/root\/.config\/Code/g' /usr/share/applications/code.desktop || true

# 7. تعيين المظهر الافتراضي للثيم والأيقونات برمجياً
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml && \
    cat << 'EOF' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Win11-Dark"/>
    <property name="IconThemeName" type="string" value="Fluent-dark"/>
  </property>
</channel>
EOF

# تنظيف كاش التثبيت
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# إعداد كلمة مرور للمستخدم root (للاتصال عبر xRDP)
RUN echo "root:mosap@123123" | chpasswd

# ضبط إعدادات xRDP ليعمل بشكل صحيح ويتعرف على واجهة XFCE بشكل قطعي ومستقر
RUN sed -i 's/port=3389/port=0.0.0.0:3389/g' /etc/xrdp/xrdp.ini && \
    echo "startxfce4" > /root/.xsession && \
    chmod +x /root/.xsession

# تهيئة ملف تشغيل مدير النوافذ الافتراضي لـ xRDP
RUN cat << 'EOF' > /etc/xrdp/startwm.sh
#!/bin/sh
if [ -r /etc/profile ]; then
    . /etc/profile
fi
if [ -r ~/.bash_profile ]; then
    . ~/.bash_profile
fi
test -x /etc/X11/Xsession && exec /etc/X11/Xsession
exec startxfce4
EOF
RUN chmod +x /etc/xrdp/startwm.sh

# فتح منفذ xRDP
EXPOSE 3389

# تشغيل الـ Services بشكل متتابع مع تنظيف الملفات المؤقتة القديمة لضمان عدم حدوث تعليق
CMD rm -rf /var/run/xrdp/* /var/run/xrdp.pid && \
    mkdir -p /var/run/xrdp /var/run/xrdp/sockdir && \
    chown -R xrdp:xrdp /var/run/xrdp && \
    /usr/sbin/xrdp-sesman --nodaemon & \
    sleep 1 && \
    exec /usr/sbin/xrdp --nodaemon
