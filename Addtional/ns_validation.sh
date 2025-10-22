# 持续监控 NS 记录变化
while true; do
  clear
  echo "$(date): 检查 mpc.run.place 的 NS 记录..."
  echo "当前 NS 记录:"
  dig NS mpc.run.place +short
  echo ""
  echo "期望的 AWS NS 记录:"
  echo "ns-406.awsdns-50.com"
  echo "ns-1310.awsdns-35.org" 
  echo "ns-965.awsdns-56.net"
  echo "ns-1618.awsdns-10.co.uk"
  echo ""
  echo "按 Ctrl+C 退出监控"
  sleep 30
done
