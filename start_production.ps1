# 🚀 营养分析小程序生产环境启动脚本 (PowerShell)
# 适用于Windows服务器环境的一键部署

param(
    [string]$Action = "deploy",
    [switch]$SkipChecks = $false,
    [switch]$Monitoring = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色定义
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$Message) Write-ColorOutput "[INFO] $Message" "Cyan" }
function Write-Success { param([string]$Message) Write-ColorOutput "[SUCCESS] $Message" "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput "[WARNING] $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "[ERROR] $Message" "Red" }

# 检查必要工具
function Test-Dependencies {
    Write-Info "检查部署依赖..."
    
    $dependencies = @("docker", "docker-compose", "curl", "git")
    $missing = @()
    
    foreach ($dep in $dependencies) {
        if (!(Get-Command $dep -ErrorAction SilentlyContinue)) {
            $missing += $dep
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "缺少必要工具: $($missing -join ', ')"
        Write-Info "请安装以下工具:"
        Write-Info "- Docker Desktop: https://www.docker.com/products/docker-desktop"
        Write-Info "- Git: https://git-scm.com/download/win"
        exit 1
    }
    
    Write-Success "依赖检查通过"
}

# 检查环境变量
function Test-Environment {
    Write-Info "检查环境变量配置..."
    
    if (!(Test-Path ".env")) {
        Write-Error "未找到 .env 文件"
        Write-Info "请复制 .env.example 为 .env 并配置必要参数"
        Write-Info "复制命令: Copy-Item .env.example .env"
        exit 1
    }
    
    # 读取环境变量
    $envVars = @{}
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            $envVars[$matches[1]] = $matches[2]
        }
    }
    
    # 检查关键变量
    $requiredVars = @(
        "SECRET_KEY", "DB_PASSWORD", "ALIYUN_ACCESS_KEY_ID", 
        "ALIYUN_ACCESS_KEY_SECRET", "WECHAT_APP_ID", "WECHAT_APP_SECRET"
    )
    
    $missingVars = @()
    foreach ($var in $requiredVars) {
        if (!$envVars.ContainsKey($var) -or [string]::IsNullOrEmpty($envVars[$var])) {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Error "缺少必要的环境变量: $($missingVars -join ', ')"
        exit 1
    }
    
    # 检查密钥强度
    if ($envVars["SECRET_KEY"].Length -lt 32) {
        Write-Warning "SECRET_KEY 长度建议至少32位"
    }
    
    Write-Success "环境变量检查通过"
}

# 创建必要目录
function New-RequiredDirectories {
    Write-Info "创建必要目录..."
    
    $directories = @(
        "uploads", "logs", "nginx\ssl", "database", 
        "monitoring", "backups", "monitoring\grafana\dashboards",
        "monitoring\grafana\datasources"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "创建目录: $dir"
        }
    }
    
    Write-Success "目录创建完成"
}

# 生成SSL证书（自签名，用于测试）
function New-SSLCertificate {
    Write-Info "生成SSL证书..."
    
    $certPath = "nginx\ssl"
    if (!(Test-Path "$certPath\cert.pem")) {
        Write-Warning "未找到SSL证书，生成自签名证书用于测试"
        
        # 使用OpenSSL生成自签名证书（如果可用）
        if (Get-Command openssl -ErrorAction SilentlyContinue) {
            & openssl req -x509 -newkey rsa:4096 -keyout "$certPath\private.key" -out "$certPath\cert.pem" -days 365 -nodes -subj "/C=CN/ST=Zhejiang/L=Jiaxing/O=NutritionApp/CN=localhost"
            Write-Success "SSL证书生成完成"
        } else {
            Write-Warning "未安装OpenSSL，请手动配置SSL证书"
            Write-Info "生产环境请使用Let's Encrypt或购买正式证书"
        }
    }
}

# 构建Docker镜像
function Build-DockerImages {
    Write-Info "构建Docker镜像..."
    
    try {
        & docker-compose build --no-cache app
        if ($LASTEXITCODE -ne 0) {
            throw "Docker镜像构建失败"
        }
        Write-Success "镜像构建完成"
    }
    catch {
        Write-Error "镜像构建失败: $_"
        exit 1
    }
}

# 初始化数据库
function Initialize-Database {
    Write-Info "初始化数据库..."
    
    # 启动数据库服务
    & docker-compose up -d db redis
    
    # 等待数据库启动
    Write-Info "等待数据库启动..."
    Start-Sleep -Seconds 30
    
    # 检查数据库连接
    $maxAttempts = 10
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        Write-Info "数据库连接测试 $attempt/$maxAttempts"
        
        try {
            & docker-compose exec -T db pg_isready -U nutrition_user -d nutrition_db
            if ($LASTEXITCODE -eq 0) {
                Write-Success "数据库连接正常"
                break
            }
        }
        catch {
            # 继续尝试
        }
        
        if ($attempt -eq $maxAttempts) {
            Write-Error "数据库连接失败"
            exit 1
        }
        
        Start-Sleep -Seconds 10
        $attempt++
    }
    
    Write-Success "数据库初始化完成"
}

# 启动服务
function Start-Services {
    Write-Info "启动所有服务..."
    
    $services = @("app", "db", "redis", "nginx")
    if ($Monitoring) {
        $services += @("prometheus", "grafana")
    }
    
    try {
        if ($Monitoring) {
            & docker-compose --profile monitoring up -d @services
        } else {
            & docker-compose up -d @services
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "服务启动失败"
        }
        
        Write-Info "等待服务启动..."
        Start-Sleep -Seconds 60
        
        Write-Success "服务启动完成"
    }
    catch {
        Write-Error "服务启动失败: $_"
        Show-ServiceLogs
        exit 1
    }
}

# 健康检查
function Test-ServiceHealth {
    Write-Info "执行健康检查..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        Write-Info "健康检查尝试 $attempt/$maxAttempts"
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost/health" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "应用健康检查通过"
                break
            }
        }
        catch {
            # 继续尝试
        }
        
        if ($attempt -eq $maxAttempts) {
            Write-Error "健康检查失败，服务可能未正常启动"
            Show-ServiceLogs
            exit 1
        }
        
        Start-Sleep -Seconds 10
        $attempt++
    }
    
    # 检查各个端点
    $endpoints = @("/health", "/api/health")
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost$endpoint" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "端点 $endpoint 检查通过"
            } else {
                Write-Warning "端点 $endpoint 检查失败"
            }
        }
        catch {
            Write-Warning "端点 $endpoint 检查失败: $_"
        }
    }
}

# 显示服务日志
function Show-ServiceLogs {
    Write-Info "显示服务日志..."
    & docker-compose logs --tail=50 app
}

# 显示服务状态
function Show-ServiceStatus {
    Write-Info "服务状态:"
    & docker-compose ps
    
    Write-Info "`n系统资源使用:"
    & docker stats --no-stream
}

# 备份当前版本
function Backup-CurrentVersion {
    Write-Info "备份当前版本..."
    
    $backupDir = "backups\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # 备份数据库
    try {
        & docker-compose exec -T db pg_dump -U nutrition_user nutrition_db > "$backupDir\database.sql"
        Write-Success "数据库备份完成: $backupDir\database.sql"
    }
    catch {
        Write-Warning "数据库备份失败: $_"
    }
    
    # 备份上传文件
    if ((Test-Path "uploads") -and (Get-ChildItem "uploads" -ErrorAction SilentlyContinue)) {
        Copy-Item -Path "uploads" -Destination "$backupDir\uploads" -Recurse
        Write-Success "文件备份完成: $backupDir\uploads"
    }
}

# 清理函数
function Clear-TempFiles {
    Write-Info "清理临时文件..."
    
    # 清理未使用的Docker资源
    & docker system prune -f
    
    # 清理旧的备份文件 (保留最近7天)
    $cutoffDate = (Get-Date).AddDays(-7)
    Get-ChildItem "backups" -Directory | Where-Object { $_.CreationTime -lt $cutoffDate } | Remove-Item -Recurse -Force
    
    Write-Success "清理完成"
}

# 主部署流程
function Start-Deployment {
    Write-Info "🚀 开始部署营养分析小程序..."
    
    if (!$SkipChecks) {
        Test-Dependencies
        Test-Environment
    }
    
    Backup-CurrentVersion
    New-RequiredDirectories
    New-SSLCertificate
    Build-DockerImages
    Initialize-Database
    Start-Services
    Test-ServiceHealth
    Show-ServiceStatus
    
    Write-Success "🎉 部署完成！"
    
    # 显示访问信息
    $envVars = @{}
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            $envVars[$matches[1]] = $matches[2]
        }
    }
    
    Write-Info "访问地址:"
    Write-Info "- HTTP: http://localhost"
    Write-Info "- HTTPS: https://localhost (自签名证书)"
    if ($envVars.ContainsKey("DOMAIN")) {
        Write-Info "- 生产域名: https://$($envVars['DOMAIN'])"
    }
    
    if ($Monitoring) {
        Write-Info "监控地址:"
        Write-Info "- Prometheus: http://localhost:9090"
        Write-Info "- Grafana: http://localhost:3000 (admin/admin)"
    }
}

# 主函数
function Main {
    try {
        switch ($Action.ToLower()) {
            "deploy" {
                Start-Deployment
            }
            "status" {
                Show-ServiceStatus
            }
            "logs" {
                Show-ServiceLogs
            }
            "cleanup" {
                Clear-TempFiles
            }
            "restart" {
                Write-Info "重启服务..."
                & docker-compose restart
                Test-ServiceHealth
            }
            "stop" {
                Write-Info "停止服务..."
                & docker-compose down
            }
            "backup" {
                Backup-CurrentVersion
            }
            default {
                Write-Info "用法: .\start_production.ps1 [-Action <action>] [-SkipChecks] [-Monitoring]"
                Write-Info "Actions:"
                Write-Info "  deploy   - 完整部署流程 (默认)"
                Write-Info "  status   - 显示服务状态"
                Write-Info "  logs     - 显示服务日志"
                Write-Info "  cleanup  - 清理临时文件"
                Write-Info "  restart  - 重启服务"
                Write-Info "  stop     - 停止服务"
                Write-Info "  backup   - 备份当前版本"
                Write-Info "参数:"
                Write-Info "  -SkipChecks  - 跳过依赖和环境检查"
                Write-Info "  -Monitoring  - 启用监控服务"
                exit 1
            }
        }
    }
    catch {
        Write-Error "执行失败: $_"
        exit 1
    }
}

# 捕获中断信号
trap {
    Write-Error "部署被中断"
    exit 1
}

# 执行主函数
Main