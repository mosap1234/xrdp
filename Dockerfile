FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

# 1. تثبيت KDE Plasma (الواجهة الحديثة) مع الأدوات الأساسية
RUN apt update -y && apt install --no-install-recommends -y \
    kde-plasma-desktop \
    plasma-nm \
    kdialog \
    konsole \
    dolphin \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    sudo \
    dbus-x11 \
    x11-xserver-utils \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg2 \
    unzip

# 2. تثبيت ثيم Windows 11 لـ KDE Plasma
RUN git clone --depth 1 https://github.com/vinceliuice/Win11-gtk-theme.git /tmp/win11-theme && \
    /tmp/win11-theme/install.sh -d /usr/share/themes && \
    rm -rf /tmp/win11-theme && \
    git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git /tmp/fluent-icons && \
    /tmp/fluent-icons/install.sh -d /usr/share/icons && \
    rm -rf /tmp/fluent-icons

# 3. تثبيت ثيم Windows 11 الخاص بـ KDE (لشريط المهام والقوائم)
RUN git clone --depth 1 https://github.com/Luwx/Lightly.git /tmp/lightly && \
    cd /tmp/lightly && mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && make install || true && \
    rm -rf /tmp/lightly

# 4. تحميل خلفية ويندوز 11 المظلمة
RUN mkdir -p /usr/share/backgrounds/kde && \
    curl -sSL -o /usr/share/backgrounds/kde/windows11-dark.jpg \
    https://raw.githubusercontent.com/alvatip/Windows11-Wallpapers/main/Dark/img0.jpg

# 5. تثبيت Google Chrome
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt update -y && apt install --no-install-recommends -y google-chrome-stable

# 6. تثبيت Visual Studio Code
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt update -y && apt install --no-install-recommends -y code

# 7. تعديل اختصارات البرامج لتشغيلها كـ Root بأمان
RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable %U/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox --user-data-dir=\/root\/.config\/google-chrome %U/g' /usr/share/applications/google-chrome.desktop || true && \
    sed -i 's/Exec=\/usr\/share\/code\/code/Exec=\/usr\/share\/code\/code --no-sandbox --user-data-dir=\/root\/.config\/Code/g' /usr/share/applications/code.desktop || true

# 8. تعيين إعدادات KDE Plasma للحصول على مظهر Windows 11
RUN mkdir -p /root/.config && \
    cat << 'EOF' > /root/.config/kdeglobals
[General]
ColorScheme=BreezeDark
Name=KDE Globals

[Icons]
Theme=Fluent-dark

[KDE]
WidgetStyle=Lightly

[Theme]
Name=Win11-Dark
EOF

# 9. تعيين الخلفية الافتراضية
RUN cat << 'EOF' >> /root/.config/plasma-org.kde.plasma.desktop-appletsrc
[Containments][1][Wallpaper]
Image=file:///usr/share/backgrounds/kde/windows11-dark.jpg
WallpaperPlugin=org.kde.image
EOF

# 10. تنظيف الكاش
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 11. إعداد VNC
RUN mkdir -p /root/.vnc && \
    echo "mosap@123123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# 12. إعداد سكريبت تشغيل KDE Plasma مع VNC
RUN echo '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
export XDG_CURRENT_DESKTOP=KDE\n\
export XDG_SESSION_TYPE=x11\n\
export QT_QPA_PLATFORM=xcb\n\
dbus-launch --exit-with-session startplasma-x11 & \n\
sleep 5' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# فتح منفذ VNC
EXPOSE 5901

# تشغيل السيرفر
CMD bash -c "rm -rf /tmp/.X* /tmp/.X11-unix && \
    vncserver :1 -geometry 1920x1080 -depth 24 -localhost no && \
    tail -F /root/.vnc/*.log"
