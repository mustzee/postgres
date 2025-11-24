# 03. 클라우드 관리형 데이터베이스

## 🎯 학습 목표

- AWS RDS PostgreSQL 마스터
- Google Cloud SQL 이해
- Azure Database for PostgreSQL 기초
- 클라우드 DB 모니터링 및 최적화

## ☁️ 클라우드 DB 개요

### 관리형 DB 장점

✅ **자동 백업** - 지정된 주기로 자동 백업
✅ **고가용성** - Multi-AZ 배포
✅ **자동 패치** - 보안 업데이트 자동 적용
✅ **스케일링** - 쉬운 리소스 확장
✅ **모니터링** - 통합 대시보드
✅ **재해 복구** - PITR (Point-in-Time Recovery)

### 클라우드 DB 비교

| 기능 | AWS RDS | Google Cloud SQL | Azure Database |
|------|---------|------------------|----------------|
| 엔진 버전 | PostgreSQL 11-16 | PostgreSQL 11-16 | PostgreSQL 11-16 |
| 최대 스토리지 | 64TB | 64TB | 16TB |
| IOPS | 최대 80,000 | 최대 60,000 | 최대 80,000 |
| 읽기 복제본 | 최대 15개 | 최대 10개 | 최대 5개 |
| 백업 보관 | 최대 35일 | 최대 365일 | 최대 35일 |
| PITR | ✅ | ✅ | ✅ |

## 🌐 AWS RDS PostgreSQL

### RDS 인스턴스 생성 (AWS CLI)

```bash
# RDS 인스턴스 생성
aws rds create-db-instance \
  --db-instance-identifier myapp-postgres \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username postgres \
  --master-user-password MySecurePassword123! \
  --allocated-storage 20 \
  --storage-type gp3 \
  --storage-encrypted \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --vpc-security-group-ids sg-12345678 \
  --db-subnet-group-name my-db-subnet-group \
  --publicly-accessible \
  --multi-az

# 상태 확인
aws rds describe-db-instances \
  --db-instance-identifier myapp-postgres \
  --query 'DBInstances[0].DBInstanceStatus'

# 엔드포인트 확인
aws rds describe-db-instances \
  --db-instance-identifier myapp-postgres \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### Terraform으로 RDS 생성

```hcl
# main.tf
resource "aws_db_instance" "postgres" {
  identifier           = "myapp-postgres"
  engine              = "postgres"
  engine_version      = "16.1"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp3"
  storage_encrypted   = true

  db_name  = "myappdb"
  username = "postgres"
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = false
  final_snapshot_identifier = "myapp-postgres-final-snapshot"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "MyApp PostgreSQL"
    Environment = "production"
  }
}

# 보안 그룹
resource "aws_security_group" "rds" {
  name        = "rds-postgres-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Main DB subnet group"
  }
}

# 읽기 복제본
resource "aws_db_instance" "postgres_read_replica" {
  identifier          = "myapp-postgres-read-replica"
  replicate_source_db = aws_db_instance.postgres.identifier
  instance_class      = "db.t3.micro"

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "MyApp PostgreSQL Read Replica"
  }
}
```

### RDS 연결

```bash
# psql 연결
psql -h myapp-postgres.abc123.us-east-1.rds.amazonaws.com \
     -U postgres \
     -d myappdb

# 프로그래밍 언어에서 연결
# Python (psycopg2)
import psycopg2

conn = psycopg2.connect(
    host="myapp-postgres.abc123.us-east-1.rds.amazonaws.com",
    port=5432,
    database="myappdb",
    user="postgres",
    password="MySecurePassword123!",
    sslmode="require"  # RDS는 SSL 권장
)

# Node.js (pg)
const { Pool } = require('pg');

const pool = new Pool({
  host: 'myapp-postgres.abc123.us-east-1.rds.amazonaws.com',
  port: 5432,
  database: 'myappdb',
  user: 'postgres',
  password: 'MySecurePassword123!',
  ssl: { rejectUnauthorized: false }
});
```

### RDS 백업 및 복구

```bash
# 수동 스냅샷 생성
aws rds create-db-snapshot \
  --db-instance-identifier myapp-postgres \
  --db-snapshot-identifier myapp-snapshot-$(date +%Y%m%d)

# 스냅샷 목록
aws rds describe-db-snapshots \
  --db-instance-identifier myapp-postgres

# 스냅샷에서 복구
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier myapp-postgres-restored \
  --db-snapshot-identifier myapp-snapshot-20241124

# PITR 복구
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier myapp-postgres \
  --target-db-instance-identifier myapp-postgres-pitr \
  --restore-time "2024-11-24T10:30:00Z"
```

### RDS 모니터링

```bash
# CloudWatch 메트릭 확인
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-postgres \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Performance Insights 활성화 (Terraform)
resource "aws_db_instance" "postgres" {
  # ... 기타 설정 ...

  performance_insights_enabled    = true
  performance_insights_retention_period = 7
}
```

## 🔵 Google Cloud SQL

### Cloud SQL 인스턴스 생성 (gcloud)

```bash
# Cloud SQL 인스턴스 생성
gcloud sql instances create myapp-postgres \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --storage-type=SSD \
  --storage-size=10GB \
  --storage-auto-increase \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=4 \
  --availability-type=regional

# 비밀번호 설정
gcloud sql users set-password postgres \
  --instance=myapp-postgres \
  --password=MySecurePassword123!

# 연결 정보 확인
gcloud sql instances describe myapp-postgres

# 데이터베이스 생성
gcloud sql databases create myappdb \
  --instance=myapp-postgres
```

### Terraform으로 Cloud SQL 생성

```hcl
resource "google_sql_database_instance" "postgres" {
  name             = "myapp-postgres"
  database_version = "POSTGRES_16"
  region           = "us-central1"

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 10
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }

    maintenance_window {
      day  = 7  # Sunday
      hour = 4
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.main.id
      require_ssl     = true
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }
  }

  deletion_protection = true
}

resource "google_sql_database" "database" {
  name     = "myappdb"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "user" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
```

### Cloud SQL 연결

```bash
# Cloud SQL Proxy 다운로드
curl -o cloud-sql-proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64
chmod +x cloud-sql-proxy

# Proxy 실행
./cloud-sql-proxy \
  --instances=PROJECT_ID:REGION:INSTANCE_NAME=tcp:5432 &

# psql 연결
psql -h 127.0.0.1 -U postgres -d myappdb

# Python에서 Cloud SQL Connector 사용
from google.cloud.sql.connector import Connector
import sqlalchemy

def getconn():
    connector = Connector()
    conn = connector.connect(
        "project:region:instance",
        "pg8000",
        user="postgres",
        password="password",
        db="myappdb"
    )
    return conn

pool = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=getconn,
)
```

## 🔷 Azure Database for PostgreSQL

### Azure Database 생성 (Azure CLI)

```bash
# 리소스 그룹 생성
az group create \
  --name myapp-rg \
  --location eastus

# PostgreSQL 서버 생성
az postgres flexible-server create \
  --resource-group myapp-rg \
  --name myapp-postgres \
  --location eastus \
  --admin-user postgres \
  --admin-password MySecurePassword123! \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 16 \
  --storage-size 32 \
  --backup-retention 7 \
  --high-availability Disabled

# 방화벽 규칙 추가
az postgres flexible-server firewall-rule create \
  --resource-group myapp-rg \
  --name myapp-postgres \
  --rule-name allow-all \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255

# 데이터베이스 생성
az postgres flexible-server db create \
  --resource-group myapp-rg \
  --server-name myapp-postgres \
  --database-name myappdb
```

## 🔒 보안 Best Practices

### 1. 네트워크 보안

```hcl
# AWS - VPC 내부에만 접근 허용
resource "aws_security_group_rule" "postgres_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.rds.id
}

# GCP - Private IP만 사용
resource "google_sql_database_instance" "postgres" {
  settings {
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
  }
}
```

### 2. 암호화

```bash
# RDS - 저장 데이터 암호화
aws rds create-db-instance \
  --storage-encrypted \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

# Cloud SQL - CMEK (Customer-Managed Encryption Key)
gcloud sql instances create myapp-postgres \
  --disk-encryption-key=projects/PROJECT_ID/locations/LOCATION/keyRings/KEYRING/cryptoKeys/KEY
```

### 3. Secrets 관리

```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name myapp/postgres/password \
  --secret-string "MySecurePassword123!"

# 애플리케이션에서 사용
aws secretsmanager get-secret-value \
  --secret-id myapp/postgres/password \
  --query SecretString \
  --output text

# GCP Secret Manager
echo -n "MySecurePassword123!" | \
  gcloud secrets create postgres-password --data-file=-

# Azure Key Vault
az keyvault secret set \
  --vault-name myapp-vault \
  --name postgres-password \
  --value "MySecurePassword123!"
```

## 📊 모니터링 및 알림

### CloudWatch Alarms (AWS)

```hcl
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## 🛠️ 실습 과제

### 과제 1: RDS 인스턴스 생성
1. AWS 프리티어로 RDS 인스턴스 생성
2. 로컬에서 연결 테스트
3. 데이터베이스 및 테이블 생성

### 과제 2: Terraform 인프라 코드화
1. Terraform으로 RDS 생성
2. 보안 그룹 설정
3. 백업 정책 구성

### 과제 3: 모니터링 설정
1. CloudWatch 대시보드 생성
2. 알람 설정 (CPU, 메모리, 연결)
3. 느린 쿼리 로그 활성화

## ✅ 체크리스트

- [ ] AWS RDS 인스턴스 생성
- [ ] Google Cloud SQL 또는 Azure Database 생성
- [ ] Terraform으로 인프라 코드화
- [ ] VPC 피어링 또는 Private Link 설정
- [ ] 읽기 복제본 생성
- [ ] 자동 백업 및 PITR 테스트
- [ ] CloudWatch/Stackdriver 모니터링 설정
- [ ] 느린 쿼리 로그 분석
- [ ] Secrets Manager로 자격증명 관리

## 📚 다음 단계

- [Phase 3: 고급 주제](../../phase3-advanced/)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)

---

**완료 예상 시간**: 12-15시간
**난이도**: ⭐⭐⭐⭐☆
