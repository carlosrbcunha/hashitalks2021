# HashiTalks 2021 Demo

## Don't be afraid of CSI

### Demo design

This demo supports the presentation **Don't be afraid of CSI** by creating, in Azure, a small infrastructure with the following services:

- 1 **Gateway server** ( Nomad server/client + Consul server )
- 3 **Docker servers** ( Nomad client )
- 3 **Azure Managed Disks** ( used to host CSI volumes )

After CSI is deployed we can deploy several applications:

- **Traefik** (Reverse proxy)
- **Sonarqube**
- **Postgres** with **PGAdmin** frontend

### Layout
![Infrastructure layout](https://github.com/carlosrbcunha/hashitalks2021/blob/master/infra_layout.jpg?raw=true)
### Pre-requisites

- Terraform >= 0.13.6
- Consul >= 1.7.4
- Azure subscription

### Deployment

Fill out the **creds** file with your azure subscription details.
Verify the **csi_disks** file to check the managed disk that will be created.

Navigate to folder demo_azure and execute the following commands:

```bash
terraform init
terraform apply -var-file ../csi_disks -var-file ../creds
```

Review tbe presented plan and enter **yes** to start the deployment.

After Terraform finished applying the plan, review the output information as you will need it to the next phase.

### Configure access the the infrastructure

In the output you will get something like this:

**nomad_address = http://40.118.88.145:4646**

With this information, configure the environment variables for nomad and consul

```bash
export NOMAD_ADDR=http://40.118.88.145:4646
export CONSUL_HTTP_ADDR=http://40.118.88.145:8500
```

After this you should create some entries in your hosts file to allow seamless access the the site as follows:

```txt
40.118.88.145   hashitalks2021.local
40.118.88.145   sonarqube.hashitalks2021.local
40.118.88.145   postgres.hashitalks2021.local
```

### Deploy CSI workloads and plugins

Navigate to folder **nomad_csi** and execute the following command

```bash
terraform apply -var-file ../csi_disks -var-file ../creds -var="infra=demo_azure"
```

This will deploy the CSI plugin that will take care of mounting the disks requested by the various workloads.

After this you can start deploying the applications, starting with **traefik**.

```bash
nomad job run -hcl1 nomad_jobs/traefik.nomad
nomad job run -hcl1 nomad_jobs/postgresql.nomad
nomad job run -hcl1 nomad_jobs/sonarqube.nomad
```

You can navigate to the various application with this links

- Nomad UI : [http://hashitalks2021.local:4646](http://hashitalks2021.local:4646)
- Consul UI : [http://hashitalks2021.local:8500](http://hashitalks2021.local:8500)
- Traefik : [http://hashitalks2021.local:8080](http://hashitalks2021.local:8080)
- Sonarqube : [http://sonarqube.hashitalks2021.local](http://sonarqube.hashitalks2021.local)
- Postgres : [http://postgres.hashitalks2021.local](http://postgres.hashitalks2021.local)