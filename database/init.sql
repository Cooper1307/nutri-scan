-- 🗄️ 营养分析小程序数据库初始化脚本
-- 创建生产环境所需的数据库结构和初始数据

-- 设置字符编码
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    openid VARCHAR(100) UNIQUE NOT NULL,
    nickname VARCHAR(100),
    avatar_url TEXT,
    age INTEGER,
    gender VARCHAR(10),
    health_conditions TEXT,
    dietary_preferences TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建分析历史表
CREATE TABLE IF NOT EXISTS analysis_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    image_path VARCHAR(500) NOT NULL,
    result_json TEXT NOT NULL,
    analysis_type VARCHAR(50) DEFAULT 'nutrition',
    confidence_score DECIMAL(5,4),
    processing_time_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建营养数据表
CREATE TABLE IF NOT EXISTS nutrition_data (
    id SERIAL PRIMARY KEY,
    food_name VARCHAR(200) NOT NULL,
    calories_per_100g DECIMAL(8,2),
    protein_per_100g DECIMAL(8,2),
    fat_per_100g DECIMAL(8,2),
    carbs_per_100g DECIMAL(8,2),
    fiber_per_100g DECIMAL(8,2),
    sodium_per_100g DECIMAL(8,2),
    sugar_per_100g DECIMAL(8,2),
    vitamin_c_per_100g DECIMAL(8,2),
    calcium_per_100g DECIMAL(8,2),
    iron_per_100g DECIMAL(8,2),
    category VARCHAR(100),
    source VARCHAR(100) DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建用户偏好表
CREATE TABLE IF NOT EXISTS user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    preference_type VARCHAR(50) NOT NULL,
    preference_value TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, preference_type)
);

-- 创建系统日志表
CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    log_level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    module VARCHAR(100),
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    request_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建API使用统计表
CREATE TABLE IF NOT EXISTS api_usage_stats (
    id SERIAL PRIMARY KEY,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_openid ON users(openid);
CREATE INDEX IF NOT EXISTS idx_analysis_history_user_id ON analysis_history(user_id);
CREATE INDEX IF NOT EXISTS idx_analysis_history_created_at ON analysis_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_nutrition_data_food_name ON nutrition_data(food_name);
CREATE INDEX IF NOT EXISTS idx_nutrition_data_category ON nutrition_data(category);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_created_at ON system_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_logs_log_level ON system_logs(log_level);
CREATE INDEX IF NOT EXISTS idx_api_usage_stats_endpoint ON api_usage_stats(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_usage_stats_created_at ON api_usage_stats(created_at DESC);

-- 创建全文搜索索引
CREATE INDEX IF NOT EXISTS idx_nutrition_data_food_name_gin ON nutrition_data USING gin(food_name gin_trgm_ops);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为相关表创建更新时间触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_analysis_history_updated_at ON analysis_history;
CREATE TRIGGER update_analysis_history_updated_at
    BEFORE UPDATE ON analysis_history
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_nutrition_data_updated_at ON nutrition_data;
CREATE TRIGGER update_nutrition_data_updated_at
    BEFORE UPDATE ON nutrition_data
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 插入基础营养数据
INSERT INTO nutrition_data (food_name, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_per_100g, category) VALUES
('白米饭', 130, 2.7, 0.3, 28, 0.4, 5, '主食'),
('全麦面包', 247, 13, 4.2, 41, 7, 491, '主食'),
('鸡胸肉', 165, 31, 3.6, 0, 0, 74, '肉类'),
('三文鱼', 208, 20, 13, 0, 0, 59, '海鲜'),
('鸡蛋', 155, 13, 11, 1.1, 0, 124, '蛋类'),
('牛奶', 42, 3.4, 1, 5, 0, 44, '乳制品'),
('酸奶', 59, 10, 0.4, 3.6, 0, 36, '乳制品'),
('苹果', 52, 0.3, 0.2, 14, 2.4, 1, '水果'),
('香蕉', 89, 1.1, 0.3, 23, 2.6, 1, '水果'),
('橙子', 47, 0.9, 0.1, 12, 2.4, 0, '水果'),
('西兰花', 34, 2.8, 0.4, 7, 2.6, 33, '蔬菜'),
('胡萝卜', 41, 0.9, 0.2, 10, 2.8, 69, '蔬菜'),
('菠菜', 23, 2.9, 0.4, 3.6, 2.2, 79, '蔬菜'),
('番茄', 18, 0.9, 0.2, 3.9, 1.2, 5, '蔬菜'),
('土豆', 77, 2, 0.1, 17, 2.2, 6, '蔬菜'),
('核桃', 654, 15, 65, 14, 6.7, 2, '坚果'),
('杏仁', 579, 21, 50, 22, 12, 1, '坚果'),
('燕麦', 389, 17, 7, 66, 11, 2, '谷物'),
('糙米', 370, 8, 3, 77, 4, 7, '谷物'),
('豆腐', 76, 8, 4.8, 1.9, 0.4, 7, '豆制品')
ON CONFLICT DO NOTHING;

-- 创建数据库视图
CREATE OR REPLACE VIEW user_analysis_summary AS
SELECT 
    u.id as user_id,
    u.openid,
    u.nickname,
    COUNT(ah.id) as total_analyses,
    AVG(ah.confidence_score) as avg_confidence,
    AVG(ah.processing_time_ms) as avg_processing_time,
    MAX(ah.created_at) as last_analysis_date,
    MIN(ah.created_at) as first_analysis_date
FROM users u
LEFT JOIN analysis_history ah ON u.id = ah.user_id
GROUP BY u.id, u.openid, u.nickname;

-- 创建分区表（用于大数据量的日志表）
CREATE TABLE IF NOT EXISTS system_logs_partitioned (
    LIKE system_logs INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- 创建当月分区
CREATE TABLE IF NOT EXISTS system_logs_current PARTITION OF system_logs_partitioned
FOR VALUES FROM (date_trunc('month', CURRENT_DATE)) TO (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month');

-- 设置表注释
COMMENT ON TABLE users IS '用户基础信息表';
COMMENT ON TABLE analysis_history IS '营养分析历史记录表';
COMMENT ON TABLE nutrition_data IS '营养成分数据表';
COMMENT ON TABLE user_preferences IS '用户偏好设置表';
COMMENT ON TABLE system_logs IS '系统日志表';
COMMENT ON TABLE api_usage_stats IS 'API使用统计表';

-- 设置列注释
COMMENT ON COLUMN users.openid IS '微信用户唯一标识';
COMMENT ON COLUMN analysis_history.result_json IS '分析结果JSON数据';
COMMENT ON COLUMN analysis_history.confidence_score IS '分析置信度分数(0-1)';
COMMENT ON COLUMN nutrition_data.calories_per_100g IS '每100克热量(千卡)';

-- 创建数据库函数
CREATE OR REPLACE FUNCTION get_user_nutrition_summary(user_openid VARCHAR)
RETURNS TABLE(
    total_analyses INTEGER,
    avg_calories DECIMAL,
    avg_protein DECIMAL,
    last_analysis_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(ah.id)::INTEGER as total_analyses,
        AVG((ah.result_json::json->>'calories')::decimal) as avg_calories,
        AVG((ah.result_json::json->>'protein')::decimal) as avg_protein,
        MAX(ah.created_at) as last_analysis_date
    FROM users u
    JOIN analysis_history ah ON u.id = ah.user_id
    WHERE u.openid = user_openid;
END;
$$ LANGUAGE plpgsql;

-- 创建清理旧数据的函数
CREATE OR REPLACE FUNCTION cleanup_old_data(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 清理旧的系统日志
    DELETE FROM system_logs 
    WHERE created_at < CURRENT_DATE - INTERVAL '1 day' * days_to_keep;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- 清理旧的API统计数据
    DELETE FROM api_usage_stats 
    WHERE created_at < CURRENT_DATE - INTERVAL '1 day' * days_to_keep;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 授权
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nutrition_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nutrition_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO nutrition_user;

-- 完成初始化
INSERT INTO system_logs (log_level, message, module) 
VALUES ('INFO', '数据库初始化完成', 'database_init');

SELECT 'Database initialization completed successfully!' as status;