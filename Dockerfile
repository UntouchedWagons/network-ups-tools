FROM debian:sid-slim
LABEL org.opencontainers.image.authors="untouchedwagons@fastmail.com"

RUN apt-get update && apt-get install -y nut nut-snmp

COPY scripts/run.sh /root/run.sh
COPY configs/nut.conf /etc/nut/nut.conf
COPY configs/upsd.conf /etc/nut/upsd.conf

RUN chmod 0744 /root/run.sh

CMD ["/root/run.sh"]
