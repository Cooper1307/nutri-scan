# 🥗 营养分析小程序

一个基于微信小程序的智能营养分析系统，通过拍照识别食物并提供详细的营养成分分析。

## 📋 项目概述

### 核心功能
- 📸 **智能拍照识别** - 使用阿里云OCR技术识别食物
- 🔍 **营养成分分析** - 提供详细的营养数据和建议
- 📊 **历史记录管理** - 保存和查看分析历史
- 👤 **用户系统** - 微信授权登录
- 📱 **适老化设计** - 大字体、简洁界面

### 技术栈

#### 后端 (Backend)
- **框架**: FastAPI + Python 3.9
- **数据库**: PostgreSQL + SQLAlchemy ORM
- **缓存**: Redis
- **OCR服务**: 阿里云通用文字识别
- **认证**: 微信小程序授权
- **部署**: Docker + Docker Compose

#### 前端 (Frontend)
- **框架**: 微信小程序原生开发
- **UI组件**: WeUI
- **状态管理**: 小程序全局数据
- **网络请求**: wx.request

#### 基础设施
- **容器化**: Docker + Docker Compose
- **反向代理**: Nginx
- **监控**: Prometheus + Grafana
- **SSL**: Let's Encrypt / 自签名证书
- **CI/CD**: 自动化部署脚本

## 🏗️ 项目架构

```
营养分析小程序
├── 前端 (微信小程序)
│   ├── 用户界面层
│   ├── 业务逻辑层
│   └── 数据访问层
│
├── 后端 (FastAPI)
│   ├── API网关层
│   ├── 业务服务层
│   ├── 数据访问层
│   └── 外部服务集成
│
├── 数据层
│   ├── PostgreSQL (主数据库)
│   ├── Redis (缓存)
│   └── 文件存储
│
└── 基础设施
    ├── Docker容器
    ├── Nginx代理
    ├── 监控系统
    └── 安全防护
```

## 📁 目录结构

```
miniprogram/
├── backend/                    # 后端代码
│   ├── app/
│   │   ├── api/               # API路由
│   │   ├── core/              # 核心配置
│   │   ├── models/            # 数据模型
│   │   ├── schemas/           # Pydantic模式
│   │   ├── services/          # 业务服务
│   │   └── utils/             # 工具函数
│   ├── config/                # 配置文件
│   ├── tests/                 # 测试文件
│   └── requirements.txt       # Python依赖
│
├── frontend/                   # 前端代码
│   ├── pages/                 # 页面文件
│   ├── components/            # 组件文件
│   ├── utils/                 # 工具函数
│   ├── app.js                 # 应用入口
│   ├── app.json               # 应用配置
│   └── app.wxss               # 全局样式
│
├── database/                   # 数据库相关
│   └── init.sql               # 初始化脚本
│
├── nginx/                      # Nginx配置
│   ├── nginx.conf             # 主配置文件
│   └── ssl/                   # SSL证书
│
├── monitoring/                 # 监控配置
│   ├── prometheus.yml         # Prometheus配置
│   ├── alert_rules.yml        # 告警规则
│   └── grafana/               # Grafana配置
│
├── docker-compose.yml          # Docker编排
├── Dockerfile                  # Docker镜像
├── .env.example               # 环境变量模板
├── start_production.sh        # Linux部署脚本
├── start_production.ps1       # Windows部署脚本
└── README.md                  # 项目文档
```

## 🚀 快速开始

### 环境要求

- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- **Git**
- **微信开发者工具**

### 1. 克隆项目

```bash
git clone <repository-url>
cd miniprogram
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
vim .env
```

**必需配置项**:
```env
# 安全密钥
SECRET_KEY=your-secret-key-32-chars-minimum

# 数据库
DB_PASSWORD=your-database-password

# 阿里云OCR
ALIYUN_ACCESS_KEY_ID=your-aliyun-access-key-id
ALIYUN_ACCESS_KEY_SECRET=your-aliyun-access-key-secret

# 微信小程序
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret
```

### 3. 部署应用

#### Linux/macOS
```bash
# 赋予执行权限
chmod +x start_production.sh

# 一键部署
./start_production.sh deploy

# 启用监控
./start_production.sh deploy --monitoring
```

#### Windows
```powershell
# 一键部署
.\start_production.ps1 -Action deploy

# 启用监控
.\start_production.ps1 -Action deploy -Monitoring
```

### 4. 验证部署

访问以下地址验证部署状态：
- **应用健康检查**: http://localhost/health
- **API文档**: http://localhost/docs
- **Prometheus** (如启用): http://localhost:9090
- **Grafana** (如启用): http://localhost:3000

## 🔧 开发指南

### 后端开发

#### 本地开发环境
```bash
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate     # Windows

# 安装依赖
pip install -r requirements.txt

# 启动开发服务器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### API文档
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

#### 运行测试
```bash
# 单元测试
pytest tests/

# 端到端测试
python tests/test_e2e.py

# 性能测试
python tests/test_performance.py
```

### 前端开发

#### 微信开发者工具
1. 打开微信开发者工具
2. 导入项目 `frontend/` 目录
3. 配置AppID
4. 开始开发调试

#### 配置后端地址
```javascript
// frontend/utils/config.js
const config = {
  baseURL: 'http://localhost:8000/api',  // 开发环境
  // baseURL: 'https://your-domain.com/api',  // 生产环境
}
```

## 📊 监控和运维

### 服务管理

```bash
# 查看服务状态
./start_production.sh status

# 查看日志
./start_production.sh logs

# 重启服务
./start_production.sh restart

# 停止服务
./start_production.sh stop

# 备份数据
./start_production.sh backup

# 清理临时文件
./start_production.sh cleanup
```

### 监控指标

#### 应用指标
- **响应时间**: API请求响应时间
- **错误率**: HTTP 4xx/5xx错误比例
- **吞吐量**: 每秒请求数 (RPS)
- **并发用户**: 同时在线用户数

#### 系统指标
- **CPU使用率**: 服务器CPU负载
- **内存使用率**: 内存占用情况
- **磁盘使用率**: 存储空间使用
- **网络流量**: 入站/出站流量

#### 业务指标
- **用户注册数**: 新用户注册趋势
- **图片分析次数**: 功能使用频率
- **OCR成功率**: 识别准确性
- **用户留存率**: 用户活跃度

### 告警配置

系统配置了以下告警规则：
- 应用服务不可用
- API错误率 > 5%
- 响应时间 > 2秒
- 数据库连接失败
- 磁盘使用率 > 85%
- 内存使用率 > 90%

## 🔒 安全最佳实践

### 数据安全
- **加密传输**: 全站HTTPS
- **数据加密**: 敏感数据加密存储
- **访问控制**: 基于角色的权限管理
- **审计日志**: 完整的操作日志记录

### 网络安全
- **防火墙**: 限制不必要的端口访问
- **DDoS防护**: 请求频率限制
- **SQL注入防护**: 参数化查询
- **XSS防护**: 输入验证和输出编码

### 运维安全
- **定期备份**: 自动化数据备份
- **安全更新**: 及时更新依赖包
- **监控告警**: 异常行为检测
- **访问审计**: 管理员操作记录

## 📈 性能优化

### 后端优化
- **数据库索引**: 关键字段建立索引
- **连接池**: 数据库连接复用
- **缓存策略**: Redis缓存热点数据
- **异步处理**: 耗时操作异步执行

### 前端优化
- **图片压缩**: 上传前压缩图片
- **请求合并**: 减少网络请求次数
- **本地缓存**: 缓存静态资源
- **懒加载**: 按需加载内容

### 基础设施优化
- **CDN加速**: 静态资源CDN分发
- **负载均衡**: 多实例负载分担
- **容器优化**: 精简镜像大小
- **网络优化**: 启用gzip压缩

## 🚀 部署方案

### 开发环境
- **本地开发**: Docker Compose单机部署
- **功能测试**: 完整功能验证
- **性能测试**: 基础性能指标

### 测试环境
- **集成测试**: 多服务集成验证
- **压力测试**: 高并发场景测试
- **安全测试**: 安全漏洞扫描

### 生产环境
- **高可用部署**: 多实例负载均衡
- **数据备份**: 定时自动备份
- **监控告警**: 7x24小时监控
- **灾难恢复**: 快速故障恢复

## 🔄 更新和维护

### 版本更新
```bash
# 更新应用
./start_production.sh update

# 回滚版本
./start_production.sh rollback
```

### 数据库迁移
```bash
# 备份数据库
docker-compose exec db pg_dump -U nutrition_user nutrition_db > backup.sql

# 执行迁移
docker-compose exec app python -m alembic upgrade head
```

### 日志管理
```bash
# 查看应用日志
docker-compose logs -f app

# 查看Nginx日志
docker-compose logs -f nginx

# 清理旧日志
find logs -name "*.log" -mtime +30 -delete
```

## 🤝 贡献指南

### 开发流程
1. Fork项目仓库
2. 创建功能分支
3. 提交代码变更
4. 运行测试套件
5. 提交Pull Request

### 代码规范
- **Python**: 遵循PEP 8规范
- **JavaScript**: 遵循ESLint规则
- **Git提交**: 使用语义化提交信息
- **文档**: 及时更新相关文档

### 测试要求
- **单元测试**: 覆盖率 > 80%
- **集成测试**: 关键流程验证
- **性能测试**: 响应时间要求
- **安全测试**: 漏洞扫描通过

## 📞 技术支持

### 常见问题

**Q: 部署失败怎么办？**
A: 检查环境变量配置，确保Docker服务正常运行，查看错误日志定位问题。

**Q: 图片识别不准确？**
A: 确保图片清晰，光线充足，食物在画面中央，检查阿里云OCR配置。

**Q: 性能问题如何优化？**
A: 检查数据库查询效率，启用Redis缓存，优化图片大小，增加服务器资源。

### 联系方式
- **技术文档**: 查看项目Wiki
- **问题反馈**: 提交GitHub Issue
- **功能建议**: 发起Discussion

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢以下开源项目和服务：
- [FastAPI](https://fastapi.tiangolo.com/) - 现代化的Python Web框架
- [微信小程序](https://developers.weixin.qq.com/miniprogram/dev/framework/) - 小程序开发平台
- [阿里云OCR](https://www.aliyun.com/product/ocr) - 文字识别服务
- [Docker](https://www.docker.com/) - 容器化平台
- [PostgreSQL](https://www.postgresql.org/) - 开源数据库
- [Redis](https://redis.io/) - 内存数据库
- [Nginx](https://nginx.org/) - 高性能Web服务器
- [Prometheus](https://prometheus.io/) - 监控系统
- [Grafana](https://grafana.com/) - 可视化平台

---

**🎯 项目目标**: 为用户提供便捷、准确的营养分析服务，促进健康饮食习惯的养成。

**💡 技术愿景**: 构建高性能、高可用、易维护的现代化应用系统。

**🌟 用户价值**: 通过技术创新提升用户生活品质，让健康管理更加简单高效。