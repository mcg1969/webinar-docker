FROM registry.access.redhat.com/ubi8/ubi

# Create the non-root user. By assigning it to the root group we ensure that we can
# access any group-readable/group-writable content. OpenShift assigns its random UIDs
# to group 0, so this emulates that same functionality. Also disable the subscription-
# manager warning: https://serverfault.com/a/854574
RUN useradd --uid 1001 --gid 0 user --shell /sbin/nologin \
    && chown -R 1001:0 /usr/local \
    # Suppress subscription manager warning
    && sed -i 's@enabled=1@enabled=0@' /etc/yum/pluginconf.d/subscription-manager.conf \
    && dnf install -y --setopt=install_weak_deps=False nss_wrapper glibc-langpack-en
USER 1001
WORKDIR /home/user
ENV LANG=en_US.utf-8 \
    LC_ALL=en_US.utf-8

COPY --chown=1001:0 entrypoint.sh environment.txt /

# Now create /usr/local as the named user
RUN set -ex \
    && curl -O https://repo.anaconda.com/pkgs/misc/conda-execs/conda-4.7.12-linux-64.exe \
    && chmod +rx conda-4.7.12-linux-64.exe /entrypoint.sh \
    && ./conda-4.7.12-linux-64.exe create --yes --prefix /usr/local --file /environment.txt \
    && rm -rf ./conda-4.7.12-linux-64.exe ${HOME}/.conda \
    && source /usr/local/bin/activate base \
    && conda config --set auto_update_conda False --set notify_outdated_conda False --system \
    && chmod -R g=u /usr/local /home/user

ENTRYPOINT [ "/entrypoint.sh" ]
