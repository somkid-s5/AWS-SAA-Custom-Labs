#!/usr/bin/env bash
# =============================================================================
# cleanup-all-labs.sh — ลบ Resources จากทุก Lab ตามลำดับ Dependency
# =============================================================================
# ใช้งาน: bash scripts/cleanup-all-labs.sh
#
# คำเตือน:
#   - Script นี้จะพยายามลบ Resources ทั้งหมดที่สร้างใน Labs 00-24
#   - ตรวจสอบ Variables ในแต่ละ Section ก่อนรัน
#   - Labs ที่ใช้ VPC จาก Lab 01 จะถูกลบก่อน แล้วจึงลบ VPC ท้ายสุด
# =============================================================================

set -euo pipefail
AWS_REGION="${AWS_REGION:-ap-southeast-1}"
echo "🧹 Starting cleanup for all Labs (Region: $AWS_REGION)"
echo "=================================================="

# Helper function: ลบโดยไม่ error ถ้าไม่มี Resource
safe_delete() {
  eval "$@" 2>/dev/null && echo "  ✅ Done" || echo "  ⏭️  Skipped (already deleted or not found)"
}

# ===========================================================================
# PRE-FLIGHT CHECK: ดึง VPC ID จาก Lab 01 (ใช้ร่วมกัน)
# ===========================================================================
echo ""
echo "📌 ดึง Lab 01 VPC ID..."
LAB01_VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=SAA-Lab-01" \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "None")

if [ "$LAB01_VPC_ID" = "None" ] || [ -z "$LAB01_VPC_ID" ]; then
  echo "  ⚠️  ไม่พบ VPC จาก Lab 01 (อาจลบไปแล้ว)"
else
  echo "  พบ: $LAB01_VPC_ID"
fi

# ===========================================================================
# Labs ที่ใช้ VPC ของตัวเอง (ลบก่อน — ไม่มี Dependency กับ Lab 01)
# ===========================================================================

echo ""
echo "─── Lab 10: VPC Peering + Transit Gateway ───"
TGW_IDS=$(aws ec2 describe-transit-gateways \
  --filters "Name=tag:Project,Values=SAA-Lab-10" \
  --query "TransitGateways[?State!='deleted'].TransitGatewayId" \
  --output text 2>/dev/null)
if [ -n "$TGW_IDS" ]; then
  for ATT_ID in $(aws ec2 describe-transit-gateway-vpc-attachments \
    --filters "Name=transit-gateway-id,Values=$TGW_IDS" \
    --query 'TransitGatewayVpcAttachments[*].TransitGatewayAttachmentId' \
    --output text 2>/dev/null); do
    safe_delete "aws ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id $ATT_ID"
  done
  sleep 30
  for TGW_ID in $TGW_IDS; do
    safe_delete "aws ec2 delete-transit-gateway --transit-gateway-id $TGW_ID"
  done
fi
for VPC_ID in $(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=SAA-Lab-10" \
  --query 'Vpcs[*].VpcId' --output text 2>/dev/null); do
  safe_delete "aws ec2 delete-vpc --vpc-id $VPC_ID"
done

echo ""
echo "─── Lab 19: 3-Tier Architecture ───"
safe_delete "aws autoscaling update-auto-scaling-group --auto-scaling-group-name lab19-asg --min-size 0 --desired-capacity 0"
sleep 5
safe_delete "aws autoscaling delete-auto-scaling-group --auto-scaling-group-name lab19-asg --force-delete"
LAB19_ALB=$(aws elbv2 describe-load-balancers --names lab19-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "None")
if [ "$LAB19_ALB" != "None" ] && [ -n "$LAB19_ALB" ]; then
  safe_delete "aws elbv2 delete-load-balancer --load-balancer-arn $LAB19_ALB"
fi
safe_delete "aws rds delete-db-instance --db-instance-identifier lab19-db --skip-final-snapshot"
echo "  ⏳ รอ RDS ลบ (อาจใช้เวลา 5-10 นาที)..."
aws rds wait db-instance-deleted --db-instance-identifier lab19-db 2>/dev/null || true
safe_delete "aws rds delete-db-subnet-group --db-subnet-group-name lab19-rds-group"
for VPC_ID in $(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=SAA-Lab-19" \
  --query 'Vpcs[*].VpcId' --output text 2>/dev/null); do
  safe_delete "aws ec2 delete-vpc --vpc-id $VPC_ID"
done

echo ""
echo "─── Lab 20: Event-Driven Ordering ───"
ESM_UUID=$(aws lambda list-event-source-mappings \
  --function-name lab20-func-inventory \
  --query 'EventSourceMappings[0].UUID' --output text 2>/dev/null || echo "None")
if [ "$ESM_UUID" != "None" ] && [ -n "$ESM_UUID" ]; then
  safe_delete "aws lambda delete-event-source-mapping --uuid $ESM_UUID"
fi
safe_delete "aws lambda delete-function --function-name lab20-func-inventory"
safe_delete "aws iam detach-role-policy --role-name Lab20LambdaInvRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
safe_delete "aws iam delete-role --role-name Lab20LambdaInvRole"
TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn,'lab20-orders')].TopicArn" \
  --output text 2>/dev/null || echo "")
if [ -n "$TOPIC_ARN" ]; then
  aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
    --query 'Subscriptions[*].SubscriptionArn' --output text 2>/dev/null | \
    tr '\t' '\n' | while read sub; do
      aws sns unsubscribe --subscription-arn "$sub" 2>/dev/null || true
    done
  safe_delete "aws sns delete-topic --topic-arn $TOPIC_ARN"
fi
for Q in lab20-inventory lab20-inventory-dlq; do
  Q_URL=$(aws sqs get-queue-url --queue-name "$Q" --query 'QueueUrl' --output text 2>/dev/null || echo "")
  if [ -n "$Q_URL" ]; then safe_delete "aws sqs delete-queue --queue-url $Q_URL"; fi
done

echo ""
echo "─── Lab 21: Backup & DR ───"
PLAN_ID=$(aws backup list-backup-plans \
  --query "BackupPlansList[?BackupPlanName=='Lab21-Daily-With-DR'].BackupPlanId" \
  --output text 2>/dev/null || echo "")
if [ -n "$PLAN_ID" ]; then safe_delete "aws backup delete-backup-plan --backup-plan-id $PLAN_ID"; fi
safe_delete "aws backup delete-backup-vault --backup-vault-name lab21-vault"
safe_delete "aws backup delete-backup-vault --backup-vault-name lab21-vault --region ap-northeast-1"

echo ""
echo "─── Lab 22: Observability ───"
safe_delete "aws cloudwatch delete-alarms --alarm-names lab22-high-latency"
safe_delete "aws logs delete-log-group --log-group-name /lab22/app"

# ===========================================================================
# Labs ที่ใช้ VPC จาก Lab 01 (ลบ Resources ก่อน แล้วค่อยลบ VPC ท้ายสุด)
# ===========================================================================
echo ""
echo "─── Labs 02/06/08/09: Resources ที่ใช้ VPC Lab 01 ───"

# Lab 06: ALB + ASG
safe_delete "aws autoscaling delete-auto-scaling-group --auto-scaling-group-name lab06-asg --force-delete"
LAB06_ALB=$(aws elbv2 describe-load-balancers --names lab06-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "None")
if [ "$LAB06_ALB" != "None" ] && [ -n "$LAB06_ALB" ]; then
  safe_delete "aws elbv2 delete-load-balancer --load-balancer-arn $LAB06_ALB"
fi

# Lab 08: NAT Gateway
for NAT_ID in $(aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=SAA-Lab-08" "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId' --output text 2>/dev/null); do
  aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" >/dev/null || true
  echo "  ⏳ รอ NAT Gateway $NAT_ID ลบ..."
  aws ec2 wait nat-gateway-deleted \
    --filter "Name=nat-gateway-id,Values=$NAT_ID" 2>/dev/null || true
done

# Lab 05: RDS
safe_delete "aws rds delete-db-instance --db-instance-identifier lab05-db --skip-final-snapshot"
echo "  ⏳ รอ RDS lab05-db ลบ (อาจใช้เวลา 5-10 นาที)..."
aws rds wait db-instance-deleted --db-instance-identifier lab05-db 2>/dev/null || true
safe_delete "aws rds delete-db-subnet-group --db-subnet-group-name lab05-subnets"

# Security Groups จาก Labs ต่างๆ (ลบหลัง Resources ก่อน)
for SG_NAME in "lab06-alb-sg" "lab06-app-sg" "lab08-private-sg" "lab09-endpoint-sg" \
               "lab02-web-sg" "lab02-db-sg"; do
  SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$LAB01_VPC_ID" \
    --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")
  if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
    safe_delete "aws ec2 delete-security-group --group-id $SG_ID"
  fi
done

# ===========================================================================
# ลบ VPC Support Resources + VPC Lab 01 ท้ายสุด
# ===========================================================================
if [ "$LAB01_VPC_ID" != "None" ] && [ -n "$LAB01_VPC_ID" ]; then
  echo ""
  echo "─── Lab 01: ลบ VPC Foundation ท้ายสุด ───"
  echo "  ⚠️  กำลังลบ VPC $LAB01_VPC_ID และ Resources ทั้งหมด..."

  IGW_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$LAB01_VPC_ID" \
    --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
  if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
    safe_delete "aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $LAB01_VPC_ID"
    safe_delete "aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID"
  fi

  for SUB_ID in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$LAB01_VPC_ID" \
    --query 'Subnets[*].SubnetId' --output text 2>/dev/null); do
    safe_delete "aws ec2 delete-subnet --subnet-id $SUB_ID"
  done

  for RT_ID in $(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$LAB01_VPC_ID" "Name=association.main,Values=false" \
    --query 'RouteTables[*].RouteTableId' --output text 2>/dev/null); do
    safe_delete "aws ec2 delete-route-table --route-table-id $RT_ID"
  done

  safe_delete "aws ec2 delete-vpc --vpc-id $LAB01_VPC_ID"
fi

# ===========================================================================
# FINAL CHECK
# ===========================================================================
echo ""
echo "=================================================="
echo "✅ Cleanup เสร็จสิ้น — ตรวจสอบ Resources ที่อาจค้างอยู่:"
echo ""
echo "NAT Gateways:"
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[*].{ID:NatGatewayId,VPC:VpcId}' \
  --output table 2>/dev/null || echo "  ไม่มี"
echo ""
echo "Load Balancers:"
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?starts_with(LoadBalancerName,`lab`)].{Name:LoadBalancerName,State:State.Code}' \
  --output table 2>/dev/null || echo "  ไม่มี"
echo ""
echo "RDS Instances:"
aws rds describe-db-instances \
  --query 'DBInstances[?starts_with(DBInstanceIdentifier,`lab`)].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' \
  --output table 2>/dev/null || echo "  ไม่มี"
echo ""
echo "⚡ ตรวจสอบค่าใช้จ่ายล่าสุดที่ AWS Cost Explorer หรือรัน:"
echo "   aws ce get-cost-and-usage --time-period Start=\$(date +%Y-%m-01),End=\$(date +%Y-%m-%d) --granularity MONTHLY --metrics UnblendedCost"
