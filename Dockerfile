FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# 1. تثبيت الواجهة الأساسية المخففة جداً والأدوات الضرورية فقط
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-panel tigervnc-standalone-server tigervnc-common tigervnc-tools sudo \
    dbus-x11 x11-xserver-utils net-tools curl wget git tzdata \
    ca-certificates apt-transport-https software-properties-common gnupg2 unzip

# 2. تثبيت ثيم وأيقونات ويندوز 11 الرسمية للواجهة
RUN git clone --depth 1 https://github.com/vinceliuice/Win11-gtk-theme.git /tmp/win11-theme && \
    /tmp/win11-theme/install.sh -d /usr/share/themes && \
    rm -rf /tmp/win11-theme && \
    git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/fluent-icons && \
    /tmp/fluent-icons/install.sh -d /usr/share/icons && \
    rm -rf /tmp/fluent-icons

# 3. تحميل خلفية ويندوز 11 المظلمة الرسمية وتعيينها كافتراضية فوراً
RUN mkdir -p /usr/share/backgrounds/xfce && \
    curl -sSL -o /usr/share/backgrounds/xfce/xfce-blue.jpg https://raw.githubusercontent.com/alvatip/Windows11-Wallpapers/main/Dark/img0.jpg

# 4. تثبيت Google Chrome (الأسرع والأثبت للحاويات)
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt update -y && apt install --no-install-recommends -y google-chrome-stable

# 5. تثبيت Visual Studio Code
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt update -y && apt install --no-install-recommends -y code

# 6. تعديل اختصارات تشغيل البرامج لتعمل بصلاحية الـ Root بأمان وبدون مشاكل
RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable %U/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox --user-data-dir=\/root\/.config\/google-chrome %U/g' /usr/share/applications/google-chrome.desktop || true && \
    sed -i 's/Exec=\/usr\/share\/code\/code/Exec=\/usr\/share\/code\/code --no-sandbox --user-data-dir=\/root\/.config\/Code/g' /usr/share/applications/code.desktop || true

# 7. حقن إعدادات المظهر وشريط المهام السفلي لويندوز 11 برمجياً
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

RUN cat << 'EOF' > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=8;x=960;y=1056"/>
    <property name="length" type="uint" value="100"/>
    <property name="position-locked" type="boolean" value="true"/>
    <property name="size" type="uint" value="46"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="boolean" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="systray"/>
    <property name="plugin-5" type="string" value="clock"/>
  </property>
</channel>
EOF

# تنظيف كاش التثبيت لتقليص حجم الحاوية وتسريعها
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# إعدادات مجلد الـ VNC والباسورد للمستخدم root
RUN mkdir -p /root/.vnc && \
    echo "mosap@123123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# إعداد سكريبت الـ xstartup لتشغيل الواجهة بسلاسة
RUN echo '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xrdb $HOME/.Xresources\n\
exec startxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# فتح بورت VNC الأساسي
EXPOSE 5901

# تشغيل السيرفر بدقة الـ Full HD الكاملة والنقية
CMD bash -c "rm -rf /tmp/.X* /tmp/.X11-unix && vncserver :1 -geometry 1920x1080 -depth 24 -localhost no && sleep 2 && tail -f /root/.vnc/*.log"
