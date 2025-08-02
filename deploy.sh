#!/bin/bash

# 🚀 营养分析小程序生产环境部署脚本
# 自动化部署流程，确保服务稳定上线

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要工具
check_dependencies() {
    log_info "检查部署依赖..."
    
    local deps=("docker" "docker-compose" "curl" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "缺少必要工具: $dep"
            exit 1
        fi
    done
    
    log_success "依赖检查通过"
}

# 检查环境变量
check_environment() {
    log_info "检查环境变量配置..."
    
    if [ ! -f ".env" ]; then
        log_error "未找到 .env 文件，请复制 .env.example 并配置"
        exit 1
    fi
    
    # 检查关键环境变量
    source .env
    local required_vars=("SECRET_KEY" "DB_PASSWORD" "ALIYUN_ACCESS_KEY_ID" "WECHAT_APP_ID")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "环境变量 $var 未设置"
            exit 1
        fi
    done
    
    log_success "环境变量检查通过"
}

# 创建必要目录
setup_directories() {
    log_info "创建必要目录..."
    
    local dirs=("uploads" "logs" "nginx/ssl" "database" "monitoring")
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log_info "创建目录: $dir"
    done
    
    # 设置权限
    chmod 755 uploads logs
    
    log_success "目录创建完成"
}

# 构建Docker镜像
build_images() {
    log_info "构建Docker镜像..."
    
    # 构建应用镜像
    docker-compose build --no-cache app
    
    if [ $? -eq 0 ]; then
        log_success "镜像构建完成"
    else
        log_error "镜像构建失败"
        exit 1
    fi
}

# 数据库初始化
init_database() {
    log_info "初始化数据库..."
    
    # 启动数据库服务
    docker-compose up -d db redis
    
    # 等待数据库启动
    log_info "等待数据库启动..."
    sleep 30
    
    # 检查数据库连接
    if docker-compose exec -T db pg_isready -U nutrition_user -d nutrition_db; then
        log_success "数据库连接正常"
    else
        log_error "数据库连接失败"
        exit 1
    fi
    
    # 运行数据库迁移
    log_info "运行数据库迁移..."
    docker-compose run --rm app python -c "from app.database import create_tables; create_tables()"
    
    log_success "数据库初始化完成"
}

# 启动服务
start_services() {
    log_info "启动所有服务..."
    
    # 启动核心服务
    docker-compose up -d app db redis nginx
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 60
    
    log_success "服务启动完成"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "健康检查尝试 $attempt/$max_attempts"
        
        # 检查应用健康状态
        if curl -f http://localhost/health &> /dev/null; then
            log_success "应用健康检查通过"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "健康检查失败，服务可能未正常启动"
            show_logs
            exit 1
        fi
        
        sleep 10
        ((attempt++))
    done
    
    # 检查各个端点
    local endpoints=("/health" "/api/health")
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f "http://localhost$endpoint" &> /dev/null; then
            log_success "端点 $endpoint 检查通过"
        else
            log_warning "端点 $endpoint 检查失败"
        fi
    done
}

# 显示服务日志
show_logs() {
    log_info "显示服务日志..."
    docker-compose logs --tail=50 app
}

# 显示服务状态
show_status() {
    log_info "服务状态:"
    docker-compose ps
    
    log_info "\n系统资源使用:"
    docker stats --no-stream
}

# 备份当前版本
backup_current() {
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
    if [ -d "uploads" ] && [ "$(ls -A uploads)" ]; then
        cp -r uploads "$backup_dir/"
        log_success "文件备份完成: $backup_dir/uploads"
    fi
}

# 回滚函数
rollback() {
    log_warning "开始回滚..."
    
    # 停止当前服务
    docker-compose down
    
    # 恢复最新备份
    local latest_backup=$(ls -t backups/ | head -n1)
    if [ -n "$latest_backup" ]; then
        log_info "恢复备份: $latest_backup"
        
        # 恢复数据库
        if [ -f "backups/$latest_backup/database.sql" ]; then
            docker-compose up -d db
            sleep 30
            docker-compose exec -T db psql -U nutrition_user -d nutrition_db < "backups/$latest_backup/database.sql"
        fi
        
        # 恢复文件
        if [ -d "backups/$latest_backup/uploads" ]; then
            rm -rf uploads
            cp -r "backups/$latest_backup/uploads" .
        fi
        
        log_success "回滚完成"
    else
        log_error "未找到备份文件"
    fi
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    
    # 清理未使用的Docker资源
    docker system prune -f
    
    # 清理旧的备份文件 (保留最近7天)
    find backups/ -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    
    log_success "清理完成"
}

# 主部署流程
main() {
    log_info "🚀 开始部署营养分析小程序..."
    
    # 检查参数
    case "${1:-deploy}" in
        "deploy")
            check_dependencies
            check_environment
            backup_current
            setup_directories
            build_images
            init_database
            start_services
            health_check
            show_status
            log_success "🎉 部署完成！"
            log_info "访问地址: https://$(grep DOMAIN .env | cut -d'=' -f2)"
            ;;
        "rollback")
            rollback
            start_services
            health_check
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "cleanup")
            cleanup
            ;;
        "restart")
            log_info "重启服务..."
            docker-compose restart
            health_check
            ;;
        "stop")
            log_info "停止服务..."
            docker-compose down
            ;;
        *)
            echo "用法: $0 {deploy|rollback|status|logs|cleanup|restart|stop}"
            echo "  deploy   - 完整部署流程"
            echo "  rollback - 回滚到上一个版本"
            echo "  status   - 显示服务状态"
            echo "  logs     - 显示服务日志"
            echo "  cleanup  - 清理临时文件"
            echo "  restart  - 重启服务"
            echo "  stop     - 停止服务"
            exit 1
            ;;
    esac
}

# 捕获中断信号
trap 'log_error "部署被中断"; exit 1' INT TERM

# 执行主函数
main "$@"