#!/usr/bin/env bash

set -o errexit
set -o pipefail

rake generate
aws s3 cp ./public/ s3://sap1ens.com/ --recursive
sleep 5
aws cloudfront create-invalidation --distribution-id E1XUIQERL9QZH2 --paths /
