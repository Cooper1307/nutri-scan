#!/bin/bash
# 🚀 营养分析小程序生产环境启动脚本 (Linux/macOS)
# 适用于Linux服务器环境的一键部署

set -euo pipefail

# 默认参数
ACTION="deploy"
SKIP_CHECKS=false
MONITORING=false
VERBOSE=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
🚀 营养分析小程序生产环境部署脚本

用法: $0 [选项] [动作]

动作:
  deploy      完整部署流程 (默认)
  status      显示服务状态
  logs        显示服务日志
  cleanup     清理临时文件
  restart     重启服务
  stop        停止服务
  backup      备份当前版本
  update      更新应用
  rollback    回滚到上一版本

选项:
  -s, --skip-checks    跳过依赖和环境检查
  -m, --monitoring     启用监控服务
  -v, --verbose        详细输出
  -h, --help          显示此帮助信息

示例:
  $0 deploy --monitoring
  $0 status
  $0 logs --verbose
  $0 backup

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--skip-checks)
                SKIP_CHECKS=true
                shift
                ;;
            -m|--monitoring)
                MONITORING=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            deploy|status|logs|cleanup|restart|stop|backup|update|rollback)
                ACTION="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查必要工具
check_dependencies() {
    log_info "检查部署依赖..."
    
    local dependencies=("docker" "docker-compose" "curl" "git" "jq")
    local missing=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "缺少必要工具: ${missing[*]}"
        log_info "请安装以下工具:"
        log_info "Ubuntu/Debian: sudo apt-get install docker.io docker-compose curl git jq"
        log_info "CentOS/RHEL: sudo yum install docker docker-compose curl git jq"
        log_info "macOS: brew install docker docker-compose curl git jq"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行"
        log_info "请启动Docker服务: sudo systemctl start docker"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 检查环境变量
check_environment() {
    log_info "检查环境变量配置..."
    
    if [[ ! -f ".env" ]]; then
        log_error "未找到 .env 文件"
        log_info "请复制 .env.example 为 .env 并配置必要参数"
        log_info "复制命令: cp .env.example .env"
        exit 1
    fi
    
    # 检查关键变量
    local required_vars=(
        "SECRET_KEY" "DB_PASSWORD" "ALIYUN_ACCESS_KEY_ID" 
        "ALIYUN_ACCESS_KEY_SECRET" "WECHAT_APP_ID" "WECHAT_APP_SECRET"
    )
    
    local missing_vars=()
    
    # 加载环境变量
    set -a
    source .env
    set +a
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "缺少必要的环境变量: ${missing_vars[*]}"
        exit 1
    fi
    
    # 检查密钥强度
    if [[ ${#SECRET_KEY} -lt 32 ]]; then
        log_warning "SECRET_KEY 长度建议至少32位"
    fi
    
    log_success "环境变量检查通过"
}

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    
    local directories=(
        "uploads" "logs" "nginx/ssl" "database" 
        "monitoring" "backups" "monitoring/grafana/dashboards"
        "monitoring/grafana/datasources"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_debug "创建目录: $dir"
        fi
    done
    
    # 设置正确的权限
    chmod 755 uploads logs
    chmod 700 nginx/ssl
    
    log_success "目录创建完成"
}

# 生成SSL证书
generate_ssl_certificate() {
    log_info "检查SSL证书..."
    
    local cert_path="nginx/ssl"
    
    if [[ ! -f "$cert_path/cert.pem" ]]; then
        log_warning "未找到SSL证书，生成自签名证书用于测试"
        
        if command -v openssl &> /dev/null; then
            openssl req -x509 -newkey rsa:4096 -keyout "$cert_path/private.key" \
                -out "$cert_path/cert.pem" -days 365 -nodes \
                -subj "/C=CN/ST=Zhejiang/L=Jiaxing/O=NutritionApp/CN=localhost"
            
            chmod 600 "$cert_path/private.key"
            chmod 644 "$cert_path/cert.pem"
            
            log_success "SSL证书生成完成"
        else
            log_warning "未安装OpenSSL，请手动配置SSL证书"
            log_info "生产环境请使用Let's Encrypt或购买正式证书"
        fi
    else
        log_success "SSL证书已存在"
    fi
}

# 构建Docker镜像
build_docker_images() {
    log_info "构建Docker镜像..."
    
    if ! docker-compose build --no-cache app; then
        log_error "Docker镜像构建失败"
        exit 1
    fi
    
    log_success "镜像构建完成"
}

# 初始化数据库
initialize_database() {
    log_info "初始化数据库..."
    
    # 启动数据库服务
    docker-compose up -d db redis
    
    # 等待数据库启动
    log_info "等待数据库启动..."
    sleep 30
    
    # 检查数据库连接
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "数据库连接测试 $attempt/$max_attempts"
        
        if docker-compose exec -T db pg_isready -U nutrition_user -d nutrition_db; then
            log_success "数据库连接正常"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "数据库连接失败"
            show_service_logs
            exit 1
        fi
        
        sleep 10
        ((attempt++))
    done
    
    # 运行数据库迁移
    if [[ -f "database/init.sql" ]]; then
        log_info "执行数据库初始化脚本..."
        docker-compose exec -T db psql -U nutrition_user -d nutrition_db < database/init.sql
    fi
    
    log_success "数据库初始化完成"
}

# 启动服务
start_services() {
    log_info "启动所有服务..."
    
    local compose_args=()
    
    if [[ "$MONITORING" == "true" ]]; then
        compose_args+=("--profile" "monitoring")
    fi
    
    if ! docker-compose "${compose_args[@]}" up -d; then
        log_error "服务启动失败"
        show_service_logs
        exit 1
    fi
    
    log_info "等待服务启动..."
    sleep 60
    
    log_success "服务启动完成"
}

# 健康检查
check_service_health() {
    log_info "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "健康检查尝试 $attempt/$max_attempts"
        
        if curl -f -s "http://localhost/health" > /dev/null; then
            log_success "应用健康检查通过"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            log_error "健康检查失败，服务可能未正常启动"
            show_service_logs
            exit 1
        fi
        
        sleep 10
        ((attempt++))
    done
    
    # 检查各个端点
    local endpoints=("/health" "/api/health")
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f -s "http://localhost$endpoint" > /dev/null; then
            log_success "端点 $endpoint 检查通过"
        else
            log_warning "端点 $endpoint 检查失败"
        fi
    done
}

# 显示服务日志
show_service_logs() {
    log_info "显示服务日志..."
    docker-compose logs --tail=50 app
}

# 显示服务状态
show_service_status() {
    log_info "服务状态:"
    docker-compose ps
    
    echo
    log_info "系统资源使用:"
    docker stats --no-stream
    
    echo
    log_info "磁盘使用情况:"
    df -h .
}

# 备份当前版本
backup_current_version() {
    log_info "备份当前版本..."
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份数据库
    if docker-compose exec -T db pg_dump -U nutrition_user nutrition_db > "$backup_dir/database.sql"; then
        log_success "数据库备份完成: $backup_dir/database.sql"
    else
        log_warning "数据库备份失败"
    fi
    
    # 备份上传文件
    if [[ -d "uploads" ]] && [[ -n "$(ls -A uploads 2>/dev/null)" ]]; then
        cp -r uploads "$backup_dir/uploads"
        log_success "文件备份完成: $backup_dir/uploads"
    fi
    
    # 备份配置文件
    cp .env "$backup_dir/.env.backup" 2>/dev/null || true
    cp docker-compose.yml "$backup_dir/docker-compose.yml.backup" 2>/dev/null || true
    
    log_success "备份完成: $backup_dir"
}

# 清理函数
cleanup_temp_files() {
    log_info "清理临时文件..."
    
    # 清理未使用的Docker资源
    docker system prune -f
    
    # 清理旧的备份文件 (保留最近7天)
    find backups -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    
    # 清理日志文件 (保留最近30天)
    find logs -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    log_success "清理完成"
}

# 更新应用
update_application() {
    log_info "更新应用..."
    
    # 备份当前版本
    backup_current_version
    
    # 拉取最新代码
    if [[ -d ".git" ]]; then
        git pull origin main
    fi
    
    # 重新构建镜像
    build_docker_images
    
    # 重启服务
    docker-compose restart app
    
    # 健康检查
    check_service_health
    
    log_success "应用更新完成"
}

# 回滚到上一版本
rollback_version() {
    log_info "回滚到上一版本..."
    
    local latest_backup
    latest_backup=$(find backups -type d -name "*" | sort -r | head -n 1)
    
    if [[ -z "$latest_backup" ]]; then
        log_error "未找到备份文件"
        exit 1
    fi
    
    log_info "使用备份: $latest_backup"
    
    # 停止服务
    docker-compose down
    
    # 恢复数据库
    if [[ -f "$latest_backup/database.sql" ]]; then
        docker-compose up -d db
        sleep 30
        docker-compose exec -T db psql -U nutrition_user -d nutrition_db < "$latest_backup/database.sql"
        log_success "数据库恢复完成"
    fi
    
    # 恢复文件
    if [[ -d "$latest_backup/uploads" ]]; then
        rm -rf uploads
        cp -r "$latest_backup/uploads" uploads
        log_success "文件恢复完成"
    fi
    
    # 启动服务
    start_services
    check_service_health
    
    log_success "回滚完成"
}

# 主部署流程
start_deployment() {
    log_info "🚀 开始部署营养分析小程序..."
    
    if [[ "$SKIP_CHECKS" != "true" ]]; then
        check_dependencies
        check_environment
    fi
    
    backup_current_version
    create_directories
    generate_ssl_certificate
    build_docker_images
    initialize_database
    start_services
    check_service_health
    show_service_status
    
    log_success "🎉 部署完成！"
    
    # 显示访问信息
    echo
    log_info "访问地址:"
    log_info "- HTTP: http://localhost"
    log_info "- HTTPS: https://localhost (自签名证书)"
    
    if [[ -n "${DOMAIN:-}" ]]; then
        log_info "- 生产域名: https://$DOMAIN"
    fi
    
    if [[ "$MONITORING" == "true" ]]; then
        echo
        log_info "监控地址:"
        log_info "- Prometheus: http://localhost:9090"
        log_info "- Grafana: http://localhost:3000 (admin/admin)"
    fi
    
    echo
    log_info "常用命令:"
    log_info "- 查看状态: $0 status"
    log_info "- 查看日志: $0 logs"
    log_info "- 重启服务: $0 restart"
    log_info "- 停止服务: $0 stop"
}

# 主函数
main() {
    case "$ACTION" in
        deploy)
            start_deployment
            ;;
        status)
            show_service_status
            ;;
        logs)
            show_service_logs
            ;;
        cleanup)
            cleanup_temp_files
            ;;
        restart)
            log_info "重启服务..."
            docker-compose restart
            check_service_health
            ;;
        stop)
            log_info "停止服务..."
            docker-compose down
            ;;
        backup)
            backup_current_version
            ;;
        update)
            update_application
            ;;
        rollback)
            rollback_version
            ;;
        *)
            log_error "未知动作: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

# 捕获中断信号
trap 'log_error "部署被中断"; exit 1' INT TERM

# 解析参数并执行
parse_args "$@"
main