# ELK-Logging-Deploy-AWS-EKS

In this demo, I will show you how to deply ELK (Elastisearch,Logstash,Kibana) to AWS EKS for a logging system. For a security concern, I also using a domain named awsmpc.asia and using ACM for HTTPS connection, I also deployed ALB for kibana client access.

# Features

- Terraform to create ACM,DNS,Route 53 hosted zone

      - ACM for free SSL certificate
      - Update DNS for ALB with kibana.awsmpc.asia
      - Route 53 for AWS hosted zone awsmpc.asia

- GitLab for code repository CI part

- Jenkins Pipeline with Jenkinsfile for CD part

- Elasticache 7.0, Logstash 7.0, Kibana 7.0 from Elasticache Official image

    (Since my EKS don't have enough memory,So I choose tight version 7.0)

- PVC created to store logs with AWS storageclass gp3, EBS csi driver

- ALB creted for Kibana clinet access

## Usage

- GitLab manage the code repository

![gitlab](./gitlab_repo.png)

- Jenkins pipeline for the CD part

![jenkins](./jenkins_pipeline.png)

- Pods running on AWS EKS

![pods](./elk_pods_eks.png)

- Check elastisearch logs whether has the filebeat files
```shell
kubectl exec -it elasticsearch-0 -n logging -- curl -s "localhost:9200/_cat/indices?v" | grep filebe
```

![elastisearch](./check_elasticsearch_index.png)

- Check filebeat logs whether has elastisearch connected

```shell
kubectl logs filebeat-pf8wt -n logging
```

![logs](./filebeat_log_connect_elastisearch.png)

- Kibana Home page

![kibana1](./kibana_home_page.png)

- Kibana index setup

![kibana2](./kibana_setup1.png)

![kibana3](./kibana_setup_2.png)

- Kibana discovery page

![kibana_d](./kibana_Discovery.png)

- Pod details check

![Pod_details](./pod_log_details.png)