FROM alpine:3.8

EXPOSE 8080

ENV DUMBINIT_VERSION 1.2.2

ENV INIT_CONFIG /backuppc_initial_config
ENV INIT_DATA /backuppc_initial_data
ENV CONFIG /etc/BackupPC
ENV DATA /var/lib/BackupPC

ENV MAILSERVER ""
ENV PORT ""
ENV FROM ""
ENV USER ""
ENV PASSWORD ""

ADD https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_amd64 /usr/local/bin/dumb-init
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ADD lighttpd.conf /etc/lighttpd/lighttpd.conf

RUN apk --update --no-cache add \
        perl-cgi \
        rsync \
        openssh \
        msmtp \
        ca-certificates \
        su-exec \
        backuppc \
        lighttpd \
        bash \
    && mkdir -p \
        $INIT_CONFIG \
        $INIT_DATA/.ssh \
    && mv $CONFIG/* $INIT_CONFIG \
    && mv $DATA/* $INIT_DATA \
    && sed -e "s/\$Conf{ServerPort} = -1;/\$Conf{ServerPort} = 8080;/g" \
        -e "s/\$Conf{CgiAdminUsers}     = '';/\$Conf{CgiAdminUsers}     = '\*';/g" \
        -e 's/\/var\/log\/BackupPC/\/var\/lib\/BackupPC\/log/g' \
        -e 's/\/usr\/sbin\/sendmail/\/usr\/bin\/msmtp/g' \
        -i $INIT_CONFIG/config.pl \
    && echo "host *"                       >> $INIT_DATA/.ssh/config \
    && echo "    StrictHostKeyChecking no" >> $INIT_DATA/.ssh/config \
    && rm -rf \
        /var/cache/apk/* \
        /tmp/*  \
        /var/log/* \
    && chmod 4755 /bin/ping \
    && chmod 777 /tmp \
    && mkdir -p /run/backuppc/ \
    && chown backuppc:backuppc /run/backuppc \
    && chmod u+x /usr/local/bin/dumb-init \
    && chmod u+x /usr/local/bin/docker-entrypoint.sh

CMD ["/usr/local/bin/docker-entrypoint.sh"]

