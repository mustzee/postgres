# Phase 3: 고급 주제

## 🎯 Phase 3 목표

이 단계에서는 PostgreSQL의 고급 기능과 현대적인 데이터 아키텍처를 학습합니다.

## 📚 학습 내용

### [01. NoSQL 하이브리드 아키텍처](./01-nosql-hybrid/)
- ✅ PostgreSQL JSON/JSONB 완전 마스터
- ✅ PostgreSQL + Redis 연동 패턴
- ✅ PostgreSQL + MongoDB 하이브리드
- ✅ 폴리글랏 퍼시스턴스 설계

**난이도**: ⭐⭐⭐⭐⭐
**예상 시간**: 15-20시간

### 02. 데이터 파이프라인 (예정)

**주요 학습 내용**:
- Apache Airflow 기초
- ETL/ELT 파이프라인 구축
- PostgreSQL → Data Warehouse
- CDC (Change Data Capture)
- Debezium을 통한 실시간 동기화

**난이도**: ⭐⭐⭐⭐☆
**예상 시간**: 15-20시간

### 03. 모니터링 및 자동화 (예정)

**주요 학습 내용**:
- Prometheus + Grafana
- postgres_exporter 설정
- 느린 쿼리 자동 감지
- 자동 백업 및 알림
- Terraform을 통한 인프라 자동화

**난이도**: ⭐⭐⭐⭐☆
**예상 시간**: 12-15시간

## 🚀 Phase 3 시작 전 체크리스트

- [ ] Phase 1, 2 모두 완료
- [ ] EXPLAIN ANALYZE 능숙하게 사용
- [ ] 인덱스 최적화 경험
- [ ] 클라우드 DB (AWS RDS 등) 사용 경험
- [ ] Docker 및 기본 DevOps 지식
- [ ] Python 또는 Node.js 기초

## 📊 학습 순서

1. **NoSQL 하이브리드** (현재 완료)
   - JSONB 완전 마스터
   - Redis 캐싱 패턴
   - 실제 프로젝트 적용

2. **데이터 파이프라인** (예정)
   - Airflow 설치 및 설정
   - 첫 DAG 작성
   - 실시간 데이터 동기화

3. **모니터링 자동화** (예정)
   - Grafana 대시보드 구축
   - 알람 설정
   - IaC (Infrastructure as Code)

## 🛠️ 추가 도구 설치

### Apache Airflow

```bash
# Docker Compose에 추가
# 별도 airflow docker-compose.yml 사용 권장
```

### Prometheus & Grafana

```bash
# docker-compose.yml에 추가
services:
  prometheus:
    image: prom/prometheus
    # ... 설정

  grafana:
    image: grafana/grafana
    # ... 설정

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter
    # ... 설정
```

## 💡 Phase 3 학습 팁

1. **실제 프로젝트 적용**: Epicodix 등 실제 프로젝트에 즉시 적용
2. **성능 측정**: 개선 전후 비교 필수
3. **문서화**: 설정과 의사결정 과정 기록
4. **커뮤니티 활용**: Stack Overflow, PostgreSQL 포럼
5. **케이스 스터디**: 대규모 서비스 아키텍처 연구

## 📈 실무 프로젝트 아이디어

### 프로젝트 1: 실시간 대시보드
- PostgreSQL + Redis + WebSocket
- 실시간 데이터 시각화
- 성능 모니터링

### 프로젝트 2: 로그 분석 시스템
- PostgreSQL (메타데이터)
- Elasticsearch (로그 검색)
- Grafana (시각화)

### 프로젝트 3: 데이터 웨어하우스
- PostgreSQL (OLTP)
- Apache Airflow (ETL)
- BigQuery/Redshift (OLAP)

## ✅ Phase 3 완료 체크리스트

### NoSQL 하이브리드
- [ ] JSONB 활용한 실제 기능 구현
- [ ] Redis 캐싱 적용 (성능 개선 측정)
- [ ] 폴리글랏 아키텍처 설계 문서 작성

### 데이터 파이프라인
- [ ] Airflow DAG 5개 이상 작성
- [ ] 실시간 CDC 구현
- [ ] 데이터 품질 검증 로직

### 모니터링 자동화
- [ ] Grafana 대시보드 구축
- [ ] 알람 5개 이상 설정
- [ ] Terraform으로 전체 인프라 코드화

## 🎓 다음 학습 경로

### 데이터베이스 전문가
- [ ] PostgreSQL 내부 구조 학습
- [ ] 쿼리 플래너 이해
- [ ] 커스텀 확장 개발

### 데이터 엔지니어
- [ ] Spark, Kafka 학습
- [ ] 대규모 데이터 처리
- [ ] 데이터 레이크 구축

### 클라우드 아키텍트
- [ ] AWS/GCP/Azure 인증
- [ ] 멀티 리전 아키텍처
- [ ] 재해 복구 전략

## 📚 추천 학습 자료

### 책
- "Designing Data-Intensive Applications" - Martin Kleppmann
- "PostgreSQL: Up and Running" - Regina Obe
- "Database Internals" - Alex Petrov

### 온라인 강의
- [PostgreSQL DBA (Udemy)](https://www.udemy.com/)
- [Data Engineering (Coursera)](https://www.coursera.org/)
- [AWS Database Specialty](https://aws.amazon.com/certification/)

### 커뮤니티
- PostgreSQL 공식 포럼
- Reddit r/PostgreSQL
- Stack Overflow
- PostgreSQL Slack

---

**예상 완료 시간**: 40-50시간
**난이도**: ⭐⭐⭐⭐⭐

**축하합니다! Phase 3를 완료하면 PostgreSQL 전문가입니다! 🎉**
