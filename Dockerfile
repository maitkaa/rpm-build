FROM rockylinux:9

RUN dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf config-manager --set-enabled devel && \
    dnf install -y git rpm-build epel-release rpmlint rpmdevtools rsync

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
