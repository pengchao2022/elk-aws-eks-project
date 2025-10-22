pipeline {
    agent {
        label 'jenkins-agent'
    }

    environment {
        CLUSTER_NAME = "comic-website-prod"
        AWS_REGION = "us-east-1"
        NAMESPACE = "logging"
        DOMAIN_NAME = "awsmpc.asia"
        KIBANA_DOMAIN = "kibana.awsmpc.asia"
        TF_STATE_BUCKET = "terraformstatefile090909"
        TF_LOCK_TABLE = "terraform-locks"
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        choice(
            name: 'DEPLOYMENT_TYPE',
            choices: ['full', 'infrastructure-only', 'elk-only', 'dns-only'],
            description: 'Select deployment type'
        )
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'Destroy resources instead of creating'
        )
    }

    stages {
        stage('Verify Environment') {
            steps {
                script {
                    echo "Starting ELK Stack Deployment on EKS"
                    echo "Deployment Type: ${params.DEPLOYMENT_TYPE}"
                    echo "Destroy Mode: ${params.DESTROY}"
                    
                    // 使用 AWS 凭据
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        // 验证工具是否已安装
                        sh '''
                            echo "=== Verifying Required Tools ==="
                            terraform version
                            kubectl version --client
                            aws --version
                            jq --version
                            echo "All tools are available!"
                        '''
                        
                        // 配置 kubectl 访问 EKS 集群
                        sh '''
                            echo "=== Configuring kubectl for EKS ==="
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                            kubectl get nodes
                        '''
                    }
                }
            }
        }

        stage('Deploy Infrastructure') {
            when {
                expression { 
                    params.DESTROY == false && 
                    (params.DEPLOYMENT_TYPE == 'full' || params.DEPLOYMENT_TYPE == 'infrastructure-only') 
                }
            }
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        deployInfrastructure()
                    }
                }
            }
        }

        stage('Deploy ELK Stack') {
            when {
                expression { 
                    params.DESTROY == false && 
                    (params.DEPLOYMENT_TYPE == 'full' || params.DEPLOYMENT_TYPE == 'elk-only') 
                }
            }
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        deployELKStack()
                    }
                }
            }
        }

        stage('Update DNS') {
            when {
                expression { 
                    params.DESTROY == false && 
                    (params.DEPLOYMENT_TYPE == 'full' || params.DEPLOYMENT_TYPE == 'dns-only') 
                }
            }
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        updateDNS()
                    }
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.DESTROY == false }
            }
            steps {
                script {
                    healthCheck()
                }
            }
        }

        // 将 Destroy 阶段移到最后
        stage('Destroy Resources') {
            when {
                expression { params.DESTROY == true }
            }
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'dev-user-aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        echo "Starting destruction of ELK Stack resources..."
                        destroyResources()
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Build completed: ${currentBuild.result}"
                echo "Build URL: ${env.BUILD_URL}"
            }
        }
        success {
            script {
                if (params.DESTROY) {
                    echo "✅ ELK Stack resources destroyed successfully!"
                } else {
                    echo "✅ ELK Stack deployment completed successfully!"
                    echo "🌐 Kibana URL: https://${env.KIBANA_DOMAIN}"
                }
            }
        }
        failure {
            script {
                if (params.DESTROY) {
                    echo "❌ ELK Stack destruction failed!"
                } else {
                    echo "❌ ELK Stack deployment failed!"
                }
                echo "Please check the build logs for details: ${env.BUILD_URL}"
            }
        }
    }
}

// Pipeline Functions
def deployInfrastructure() {
    echo "🚀 Stage 1: Deploying Infrastructure (Route53 + ACM)"
    
    // 部署 Route53
    dir('terraform/route53') {
        sh '''
            echo "Initializing and applying Route53 Terraform..."
            terraform init
            terraform plan -out=tfplan
            terraform apply -auto-approve tfplan
        '''
        
        // 获取输出
        def route53ZoneId = sh(
            script: 'terraform output -raw route53_zone_id',
            returnStdout: true
        ).trim()
        
        def nameServers = sh(
            script: 'terraform output -json route53_name_servers',
            returnStdout: true
        ).trim()
        
        echo "Route53 Zone ID: ${route53ZoneId}"
        echo "Name Servers: ${nameServers}"
        
        env.ROUTE53_ZONE_ID = route53ZoneId
    }
    
    // 部署 ACM
    dir('terraform/acm') {
        sh '''
            echo "Initializing and applying ACM Terraform..."
            terraform init
            terraform plan -out=tfplan
            terraform apply -auto-approve tfplan
        '''
        
        // 获取 ACM 证书 ARN
        def acmCertArn = sh(
            script: 'terraform output -raw acm_certificate_arn',
            returnStdout: true
        ).trim()
        
        echo "ACM Certificate ARN: ${acmCertArn}"
        env.ACM_CERT_ARN = acmCertArn
    }
    
    // 在根目录更新 Kibana Ingress
    sh """
        echo "Updating Kibana Ingress with ACM Certificate ARN..."
        sed -i 's|alb.ingress.kubernetes.io/certificate-arn:.*|alb.ingress.kubernetes.io/certificate-arn: \"${env.ACM_CERT_ARN}\"|' k8s/kibana/kibana-ingress.yaml
        echo "✅ Kibana Ingress updated with ACM Certificate ARN"
    """
    
    echo "=== 🔔 IMPORTANT: Update Your Domain Nameservers ==="
    echo "Please update your domain registrar for ${env.DOMAIN_NAME} to use the nameservers shown above"
    echo "====================================================="
}

def deployELKStack() {
    echo "🚀 Stage 2: Deploying ELK Stack"
    
    // 应用 Kubernetes 资源
    sh '''
        echo "Creating logging namespace..."
        kubectl apply -f k8s/namespaces/logging-namespace.yaml
        
        echo "Deploying Elasticsearch..."
        kubectl apply -f k8s/elasticsearch/ -n ${NAMESPACE}
    '''
    
    // 等待 Elasticsearch 就绪
    sh '''
        echo "Waiting for Elasticsearch to be ready..."
        for i in {1..60}; do
            if kubectl wait --for=condition=ready pod -l app=elasticsearch -n ${NAMESPACE} --timeout=60s 2>/dev/null; then
                echo "✅ Elasticsearch is ready!"
                break
            fi
            echo "⏳ Elasticsearch not ready yet, attempt $i/60..."
            sleep 10
        done
    '''
    
    // 部署其他组件
    sh '''
        echo "Deploying Kibana..."
        kubectl apply -f k8s/kibana/ -n ${NAMESPACE}
        
        echo "Deploying Filebeat..."
        kubectl apply -f k8s/filebeat/ -n ${NAMESPACE}
        
        echo "Deploying Logstash..."
        kubectl apply -f k8s/logstash/ -n ${NAMESPACE}
    '''
    
    // 等待 Kibana pod 启动
    echo "⏳ Waiting for Kibana to start..."
    sh '''
        for i in {1..30}; do
            if kubectl get pods -n ${NAMESPACE} -l app=kibana --no-headers 2>/dev/null | grep -q Running; then
                echo "✅ Kibana pod is running"
                break
            fi
            echo "⏳ Kibana not running yet, attempt $i/30..."
            sleep 10
        done
    '''
    
    echo "✅ ELK Stack deployment completed!"
    echo "📝 Note: ALB provisioning may take a few minutes. Kibana will be available once ALB is ready."
}

def updateDNS() {
    echo "🚀 Stage 3: Updating DNS Records"
    
    // 获取 ALB 信息
    echo "📥 Retrieving ALB information..."
    sh '''
        for i in {1..30}; do
            ALB_DNS_NAME=$(kubectl get ingress -n ${NAMESPACE} kibana-ingress -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null || echo "")
            if [ -n "$ALB_DNS_NAME" ]; then
                echo "✅ ALB DNS Name found: $ALB_DNS_NAME"
                break
            fi
            echo "⏳ ALB not ready yet, attempt $i/30..."
            sleep 10
        done
    '''
    
    def albDnsName = sh(
        script: 'kubectl get ingress -n ${NAMESPACE} kibana-ingress -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null || echo ""',
        returnStdout: true
    ).trim()
    
    if (!albDnsName) {
        error "❌ ALB DNS name not found. ALB may not be provisioned yet. Please wait a few minutes and try again."
    }
    
    def albZoneId = sh(
        script: "aws elbv2 describe-load-balancers --region ${env.AWS_REGION} --query \"LoadBalancers[?DNSName=='${albDnsName}'].CanonicalHostedZoneId\" --output text",
        returnStdout: true
    ).trim()
    
    echo "ALB DNS Name: ${albDnsName}"
    echo "ALB Zone ID: ${albZoneId}"
    
    env.ALB_DNS_NAME = albDnsName
    env.ALB_ZONE_ID = albZoneId
    
    // 更新 DNS 记录
    dir('terraform/dns') {
        sh """
            echo "Initializing and applying DNS Terraform..."
            terraform init
            terraform plan \
                -var="alb_dns_name=${env.ALB_DNS_NAME}" \
                -var="alb_zone_id=${env.ALB_ZONE_ID}" \
                -out=tfplan
            terraform apply -auto-approve tfplan
        """
    }
    
    echo "✅ DNS records updated successfully!"
    echo "🌐 Kibana will be available at: https://${env.KIBANA_DOMAIN}"
}

def healthCheck() {
    echo "🔍 Performing Health Checks..."
    
    sh '''
        echo "=== 📊 ELK Stack Pods Status ==="
        kubectl get pods -n ${NAMESPACE} -o wide
        
        echo ""
        echo "=== 🔗 Services Status ==="
        kubectl get svc -n ${NAMESPACE}
        
        echo ""
        echo "=== 📈 Component Status ==="
        
        # 检查 Elasticsearch
        echo "Elasticsearch:"
        ES_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=elasticsearch --no-headers | wc -l)
        ES_READY=$(kubectl get pods -n ${NAMESPACE} -l app=elasticsearch --no-headers | grep "Running" | wc -l)
        echo "  Pods: ${ES_READY}/${ES_PODS} ready"
        
        # 检查 Kibana
        echo "Kibana:"
        KIBANA_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=kibana --no-headers | wc -l)
        KIBANA_READY=$(kubectl get pods -n ${NAMESPACE} -l app=kibana --no-headers | grep "Running" | wc -l)
        echo "  Pods: ${KIBANA_READY}/${KIBANA_PODS} ready"
        
        # 检查 Logstash
        echo "Logstash:"
        LOGSTASH_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=logstash --no-headers | wc -l)
        LOGSTASH_READY=$(kubectl get pods -n ${NAMESPACE} -l app=logstash --no-headers | grep "Running" | wc -l)
        echo "  Pods: ${LOGSTASH_READY}/${LOGSTASH_PODS} ready"
        
        # 检查 Filebeat
        echo "Filebeat:"
        FILEBEAT_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=filebeat --no-headers | wc -l)
        FILEBEAT_READY=$(kubectl get pods -n ${NAMESPACE} -l app=filebeat --no-headers | grep "Running" | wc -l)
        echo "  Pods: ${FILEBEAT_READY}/${FILEBEAT_PODS} ready"
        
        echo ""
        echo "=== 🌐 DNS and ALB Status ==="
        ALB_DNS=$(kubectl get ingress -n ${NAMESPACE} kibana-ingress -o jsonpath="{.status.loadBalancer.ingress[0].hostname}" 2>/dev/null || echo "Not available")
        echo "ALB DNS: ${ALB_DNS}"
        
        if [ "${ALB_DNS}" != "Not available" ]; then
            echo "✅ ALB is provisioned"
            echo "🌐 Access Kibana at: https://${KIBANA_DOMAIN}"
        else
            echo "⏳ ALB is still provisioning..."
        fi
    '''
    
    echo "✅ Health checks completed!"
}

def destroyResources() {
    echo "🗑️  Destroying ELK Stack resources..."
    
    // 删除 Kubernetes 资源
    sh '''
        echo "Deleting Kubernetes resources..."
        kubectl delete -f k8s/logstash/ -n ${NAMESPACE} --ignore-not-found=true || true
        kubectl delete -f k8s/filebeat/ -n ${NAMESPACE} --ignore-not-found=true || true
        kubectl delete -f k8s/kibana/ -n ${NAMESPACE} --ignore-not-found=true || true
        kubectl delete -f k8s/elasticsearch/ -n ${NAMESPACE} --ignore-not-found=true || true
        kubectl delete -f k8s/namespaces/logging-namespace.yaml --ignore-not-found=true || true
        echo "✅ Kubernetes resources deleted"
    '''
    
    // 销毁 DNS 记录
    dir('terraform/dns') {
        sh '''
            echo "Destroying DNS records..."
            terraform init
            terraform destroy -auto-approve
            echo "✅ DNS records destroyed"
        '''
    }
    
    // 销毁 ACM 证书
    dir('terraform/acm') {
        sh '''
            echo "Destroying ACM certificate..."
            terraform init
            terraform destroy -auto-approve
            echo "✅ ACM certificate destroyed"
        '''
    }
    
    // 销毁 Route53 区域
    dir('terraform/route53') {
        sh '''
            echo "Destroying Route53 zone..."
            terraform init
            terraform destroy -auto-approve
            echo "✅ Route53 zone destroyed"
        '''
    }
    
    echo "✅ All ELK Stack resources have been destroyed successfully!"
}