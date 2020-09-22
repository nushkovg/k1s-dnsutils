# k1s DNS Utils

This repository contains a Dockerfile which creates a simple docker image which allows for DNS, Curl and XML operations. Serves a purpose of creating DDNS Update CronJobs while using Namesilo as the DNS provider.

The `scripts` directory contains a simple Bash script which uses Namesilo's API to update the A record of the purchased domain. Can be used as the CronJob script.
