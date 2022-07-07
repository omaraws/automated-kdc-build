#!/bin/bash
set -x::
SECONDARY_KDC=$1
sudo sed -i "/kdc = <%= @external_master_kdc_server %>/a \ \ \ \ \ \ \ \ kdc = ${SECONDARY_KDC}:88" /var/aws/emr/bigtop-deploy/puppet/modules/kerberos/templates/krb5.conf
sudo sed -i "/kdc = ${SECONDARY_KDC}:88/a \ \ \ \ \ \ \ \ master_kdc = <%= @external_master_kdc_server %>" /var/aws/emr/bigtop-deploy/puppet/modules/kerberos/templates/krb5.conf
sudo sed -i "/permitted_enctypes/a \ \ \ \ \ kdc_timeout = 900" /var/aws/emr/bigtop-deploy/puppet/modules/kerberos/templates/krb5.conf