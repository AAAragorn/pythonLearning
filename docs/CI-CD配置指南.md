# CI/CD 配置完整指南

## 目录

1. [CI/CD 基础概念](#1-cicd-基础概念)
2. [GitHub Actions 配置](#2-github-actions-配置)
3. [GitLab CI/CD 配置](#3-gitlab-cicd-配置)
4. [Jenkins 配置](#4-jenkins-配置)
5. [最佳实践](#5-最佳实践)

---

## 1. CI/CD 基础概念

### 1.1 什么是 CI/CD

```
开发 → 提交代码 → CI → CD → 生产环境
        ↓         ↓    ↓
      Git      测试  部署
```

**CI (Continuous Integration) - 持续集成**:
- 自动运行测试
- 代码质量检查
- 构建应用
- 发现问题早

**CD (Continuous Deployment) - 持续部署**:
- 自动部署到测试环境
- 自动部署到生产环境
- 快速交付功能

### 1.2 CI/CD 流程

```
┌─────────────┐
│  代码提交   │
└──────┬──────┘
       ↓
┌─────────────┐
│  代码检查   │ ← Lint, Format
└──────┬──────┘
       ↓
┌─────────────┐
│  运行测试   │ ← Unit, Integration
└──────┬──────┘
       ↓
┌─────────────┐
│  构建镜像   │ ← Docker Build
└──────┬──────┘
       ↓
┌─────────────┐
│  安全扫描   │ ← Security Scan
└──────┬──────┘
       ↓
┌─────────────┐
│  部署应用   │ ← Deploy
└─────────────┘
```

---

## 2. GitHub Actions 配置

### 2.1 工作流基础

**.github/workflows/ci.yml**:

```yaml
name: CI Pipeline

# 触发条件
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

# 环境变量
env:
  PYTHON_VERSION: '3.11'

# 任务
jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: |
          pytest tests/ -v --cov=app
```

### 2.2 完整 CI 流程

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  # ===== 代码质量检查 =====
  lint:
    name: Code Quality
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install linters
        run: |
          pip install black flake8 mypy
      
      - name: Run Black
        run: black --check app tests
      
      - name: Run Flake8
        run: flake8 app tests --max-line-length=127
      
      - name: Run MyPy
        run: mypy app --ignore-missing-imports
        continue-on-error: true

  # ===== 多版本测试 =====
  test:
    name: Test (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11', '3.12']
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'
      
      - name: Install dependencies
        run: pip install -r requirements-dev.txt
      
      - name: Run tests
        run: pytest tests/ -v --cov=app --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  # ===== 安全扫描 =====
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Bandit
        run: |
          pip install bandit
          bandit -r app -f json -o bandit-report.json
        continue-on-error: true
      
      - name: Check dependencies
        run: |
          pip install safety
          safety check --json
        continue-on-error: true

  # ===== Docker 构建测试 =====
  docker:
    name: Docker Build
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Build image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          tags: test-image:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 2.3 CD 流程

**.github/workflows/cd.yml**:

```yaml
name: CD Pipeline

on:
  push:
    branches: [ main ]
    tags:
      - 'v*'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # ===== 构建并推送镜像 =====
  build:
    name: Build and Push
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    outputs:
      image: ${{ steps.meta.outputs.tags }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ===== 部署到测试环境 =====
  deploy-staging:
    name: Deploy to Staging
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_KEY }}
          script: |
            cd /opt/app
            docker-compose pull
            docker-compose up -d
      
      - name: Health check
        run: |
          sleep 10
          curl -f https://staging.example.com/health

  # ===== 部署到生产环境 =====
  deploy-production:
    name: Deploy to Production
    needs: [build, deploy-staging]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    environment:
      name: production
      url: https://example.com
    
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_KEY }}
          script: |
            cd /opt/app
            docker-compose pull
            docker-compose up -d --no-deps web
      
      - name: Health check
        run: |
          sleep 15
          curl -f https://example.com/health
      
      - name: Notify deployment
        uses: 8398a7/action-slack@v3
        if: always()
        with:
          status: ${{ job.status }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 2.4 矩阵策略

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    python: ['3.9', '3.10', '3.11']
    exclude:
      - os: macos-latest
        python: '3.9'
```

### 2.5 缓存优化

```yaml
- name: Cache pip packages
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```

---

## 3. GitLab CI/CD 配置

### 3.1 基础配置

**.gitlab-ci.yml**:

```yaml
stages:
  - test
  - build
  - deploy

variables:
  PYTHON_VERSION: "3.11"
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

# 缓存配置
cache:
  paths:
    - .cache/pip
    - venv/

# ===== 测试阶段 =====
test:
  stage: test
  image: python:$PYTHON_VERSION
  before_script:
    - pip install -r requirements-dev.txt
  script:
    - pytest tests/ -v --cov=app --cov-report=xml
  coverage: '/TOTAL.*\s+(\d+%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

# ===== 代码质量 =====
lint:
  stage: test
  image: python:$PYTHON_VERSION
  script:
    - pip install black flake8
    - black --check app tests
    - flake8 app tests

# ===== 构建镜像 =====
build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" == "main" ]; then
        docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
        docker push $CI_REGISTRY_IMAGE:latest
      fi

# ===== 部署到测试环境 =====
deploy:staging:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$DEPLOY_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
  script:
    - ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$STAGING_HOST "
        cd /opt/app &&
        docker-compose pull &&
        docker-compose up -d
      "
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

# ===== 部署到生产环境 =====
deploy:production:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$DEPLOY_KEY" | tr -d '\r' | ssh-add -
  script:
    - ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$PRODUCTION_HOST "
        cd /opt/app &&
        docker-compose pull &&
        docker-compose up -d
      "
  environment:
    name: production
    url: https://example.com
  when: manual  # 手动触发
  only:
    - main
```

### 3.2 多项目流水线

```yaml
# 触发下游项目
trigger_downstream:
  stage: deploy
  trigger:
    project: group/downstream-project
    branch: main
```

### 3.3 动态子流水线

```yaml
generate_jobs:
  stage: build
  script:
    - python generate_pipeline.py > pipeline.yml
  artifacts:
    paths:
      - pipeline.yml

run_dynamic_jobs:
  stage: deploy
  trigger:
    include:
      - artifact: pipeline.yml
        job: generate_jobs
```

---

## 4. Jenkins 配置

### 4.1 Jenkinsfile

```groovy
pipeline {
    agent any
    
    environment {
        PYTHON_VERSION = '3.11'
        DOCKER_REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'myapp'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                sh '''
                    python${PYTHON_VERSION} -m venv venv
                    . venv/bin/activate
                    pip install -r requirements-dev.txt
                '''
            }
        }
        
        stage('Lint') {
            steps {
                sh '''
                    . venv/bin/activate
                    black --check app tests
                    flake8 app tests
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    . venv/bin/activate
                    pytest tests/ -v --cov=app --cov-report=xml
                '''
            }
            post {
                always {
                    junit 'test-results/*.xml'
                    publishCoverage adapters: [coberturaAdapter('coverage.xml')]
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    docker.build("${IMAGE_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }
        
        stage('Push') {
            when {
                branch 'main'
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        docker.image("${IMAGE_NAME}:${env.BUILD_NUMBER}").push()
                        docker.image("${IMAGE_NAME}:${env.BUILD_NUMBER}").push('latest')
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sshagent(['deploy-key']) {
                    sh '''
                        ssh deploy@production-server "
                            cd /opt/app &&
                            docker-compose pull &&
                            docker-compose up -d
                        "
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend color: 'good', message: "Build #${env.BUILD_NUMBER} succeeded"
        }
        failure {
            slackSend color: 'danger', message: "Build #${env.BUILD_NUMBER} failed"
        }
    }
}
```

---

## 5. 最佳实践

### 5.1 环境管理

```yaml
# 使用环境保护规则
environment:
  name: production
  url: https://example.com

# 需要审批
deployment:
  production:
    environment: production
    when: manual
    only:
      - main
```

### 5.2 Secrets 管理

```yaml
# GitHub Actions
env:
  SECRET_KEY: ${{ secrets.SECRET_KEY }}

# GitLab CI
variables:
  SECRET_KEY: $CI_SECRET_KEY

# 使用外部 Secrets 管理
- name: Get secrets
  uses: hashicorp/vault-action@v2
  with:
    url: https://vault.example.com
    token: ${{ secrets.VAULT_TOKEN }}
    secrets: |
      secret/data/production SECRET_KEY
```

### 5.3 并行执行

```yaml
jobs:
  test-unit:
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/unit/
  
  test-integration:
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/integration/
```

### 5.4 条件执行

```yaml
# 仅在主分支
if: github.ref == 'refs/heads/main'

# 仅在标签
if: startsWith(github.ref, 'refs/tags/v')

# 基于文件变化
paths:
  - 'app/**'
  - 'requirements.txt'
```

### 5.5 通知集成

**Slack 通知**:

```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  if: always()
  with:
    status: ${{ job.status }}
    text: 'Deployment to production'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

**Email 通知**:

```yaml
- name: Send email
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Build ${{ github.run_number }} - ${{ job.status }}
    to: team@example.com
    from: CI/CD
```

### 5.6 回滚策略

```yaml
rollback:
  stage: deploy
  when: manual
  script:
    - ./scripts/deploy.sh rollback
  environment:
    name: production
    action: rollback
```

---

## 6. 监控和优化

### 6.1 流水线监控

```yaml
- name: Report metrics
  run: |
    echo "Build time: ${{ steps.build.outputs.time }}"
    echo "Test coverage: ${{ steps.test.outputs.coverage }}"
```

### 6.2 性能优化

**缓存依赖**:

```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.cache/pip
      node_modules
    key: ${{ runner.os }}-deps-${{ hashFiles('**/requirements.txt') }}
```

**并行化测试**:

```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: pytest --shard-id=${{ matrix.shard }} --num-shards=4
```

---

**相关资源**:
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [GitLab CI/CD 文档](https://docs.gitlab.com/ee/ci/)
- [Jenkins 文档](https://www.jenkins.io/doc/)
