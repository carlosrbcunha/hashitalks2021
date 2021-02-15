#!/bin/bash
echo "Start Traefik"
nomad job run -hcl1 nomad_jobs/traefik.nomad
echo "Start PGAdmin"
nomad job run -hcl1 nomad_jobs/pgadmin.nomad
echo "Start Sonarqube"
nomad job run -hcl1 nomad_jobs/sonarqube.nomad
