#!/bin/bash

useradd -m $DANTE_USER &&\
echo "${DANTE_USER}:${DANTE_PASS}" | chpasswd &&\
echo "${DANTE_USER}:$(openssl passwd -1 ${DANTE_PASS})" > /etc/dante/pam_pwdfile
echo "auth required pam_pwdfile.so pwdfile /etc/dante/pam_pwdfile" > /etc/pam.d/danted
echo "account required pam_permit.so" >> /etc/pam.d/danted
danted -f /etc/dante/dante.conf
