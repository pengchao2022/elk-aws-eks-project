# 创建 change-batch.json 文件
cat > change-batch.json << 'EOF'
{
  "Comment": "Delete ACM validation records for Terraform", 
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "_38dbe569f4f71fcfaf384183c7f531ba.mpc.run.place.",
        "Type": "CNAME", 
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "_68e30da85fcd913de932f3cc80b130c4.xlfgrmvvlj.acm-validations.aws."
          }
        ]
      }
    },
    {
      "Action": "DELETE", 
      "ResourceRecordSet": {
        "Name": "_9d8662df0e8208339433e95f42819b27.kibana.mpc.run.place.",
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "_bd5632db36a7c5fd19ff3225e050ddcc.xlfgrmvvlj.acm-validations.aws."
          }
        ]
      }
    }
  ]
}
EOF

# 执行删除
aws route53 change-resource-record-sets --hosted-zone-id Z0077830G2OGJLRYHVBK --change-batch file://change-batch.json
