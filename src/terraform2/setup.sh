#!/bin/bash -e

SCRIPT_PATH=$(cd $(dirname $0); pwd)

rm -f $SCRIPT_PATH/ansible/aws/inventory
cd $SCRIPT_PATH/aws && terraform apply
ansible-playbook -i $SCRIPT_PATH/ansible/aws/inventory $SCRIPT_PATH/ansible/site.yml

