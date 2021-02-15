#!/bin/bash
echo "Stop PGAdmin"
nomad job stop pgadmin
echo "Stop Sonarqube"
nomad job stop sonarqube
echo "Stop Traefik"
nomad job stop traefik