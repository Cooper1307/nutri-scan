# -*- coding: utf-8 -*-
"""
生产环境配置文件
包含生产环境的所有配置参数
"""

import os
from typing import Optional

class ProductionConfig:
    """生产环境配置类"""
    
    # 🔐 安全配置
    SECRET_KEY: str = os.getenv('SECRET_KEY', 'your-super-secret-key-change-in-production')
    DEBUG: bool = False
    TESTING: bool = False
    
    # 🌐 服务器配置
    HOST: str = '0.0.0.0'
    PORT: int = int(os.getenv('PORT', '8000'))
    
    # 🗄️ 数据库配置
    DATABASE_URL: str = os.getenv(
        'DATABASE_URL',
        'postgresql://username:password@localhost:5432/nutrition_db'
    )
    
    # 📁 文件存储配置
    UPLOAD_FOLDER: str = os.getenv('UPLOAD_FOLDER', '/app/uploads')
    MAX_CONTENT_LENGTH: int = 16 * 1024 * 1024  # 16MB
    ALLOWED_EXTENSIONS: set = {'png', 'jpg', 'jpeg', 'gif'}
    
    # 🔍 阿里云OCR配置
    ALIYUN_ACCESS_KEY_ID: str = os.getenv('ALIYUN_ACCESS_KEY_ID', '')
    ALIYUN_ACCESS_KEY_SECRET: str = os.getenv('ALIYUN_ACCESS_KEY_SECRET', '')
    ALIYUN_OCR_ENDPOINT: str = 'ocr-cn-shanghai.aliyuncs.com'
    
    # 📱 微信小程序配置
    WECHAT_APP_ID: str = os.getenv('WECHAT_APP_ID', '')
    WECHAT_APP_SECRET: str = os.getenv('WECHAT_APP_SECRET', '')
    
    # 🚦 限流配置
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_PER_HOUR: int = 1000
    
    # 📊 日志配置
    LOG_LEVEL: str = 'INFO'
    LOG_FILE: str = '/app/logs/app.log'
    LOG_MAX_BYTES: int = 10 * 1024 * 1024  # 10MB
    LOG_BACKUP_COUNT: int = 5
    
    # 🔄 Redis配置 (用于缓存和会话)
    REDIS_URL: str = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
    
    # 🌍 CORS配置
    CORS_ORIGINS: list = [
        'https://your-domain.com',
        'https://www.your-domain.com'
    ]
    
    # 📈 监控配置
    SENTRY_DSN: Optional[str] = os.getenv('SENTRY_DSN')
    ENABLE_METRICS: bool = True
    
    # 🔒 安全头配置
    SECURITY_HEADERS: dict = {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
    }
    
    @classmethod
    def validate_config(cls) -> bool:
        """验证生产环境配置是否完整"""
        required_vars = [
            'SECRET_KEY',
            'DATABASE_URL',
            'ALIYUN_ACCESS_KEY_ID',
            'ALIYUN_ACCESS_KEY_SECRET',
            'WECHAT_APP_ID',
            'WECHAT_APP_SECRET'
        ]
        
        missing_vars = []
        for var in required_vars:
            if not getattr(cls, var) or getattr(cls, var) == '':
                missing_vars.append(var)
        
        if missing_vars:
            print(f"❌ 缺少必要的环境变量: {', '.join(missing_vars)}")
            return False
        
        print("✅ 生产环境配置验证通过")
        return True

# 配置实例
config = ProductionConfig()