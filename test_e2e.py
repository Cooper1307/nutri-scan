#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
端到端测试脚本
测试营养健康小程序的核心功能流程
"""

import requests
import json
import os
from pathlib import Path

# 配置
API_BASE_URL = "http://192.168.11.101:8000"
TEST_IMAGE_PATH = "static/images"  # 测试图片目录

def test_login():
    """测试用户登录接口"""
    print("\n=== 测试用户登录 ===")
    
    # 模拟微信登录code
    test_code = "test_code_123"
    
    response = requests.post(
        f"{API_BASE_URL}/api/login",
        json={"code": test_code}
    )
    
    print(f"状态码: {response.status_code}")
    print(f"响应: {response.json()}")
    
    if response.status_code == 200:
        data = response.json()
        return data.get('user_id')
    return None

def test_analyze_image(user_id, image_path):
    """测试图片分析接口"""
    print(f"\n=== 测试图片分析: {image_path} ===")
    
    if not os.path.exists(image_path):
        print(f"测试图片不存在: {image_path}")
        return None
    
    with open(image_path, 'rb') as f:
        files = {'file': (os.path.basename(image_path), f, 'image/png')}
        data = {'user_id': user_id}
        
        response = requests.post(
            f"{API_BASE_URL}/api/analyze",
            files=files,
            data=data
        )
    
    print(f"状态码: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"分析结果: {json.dumps(result, ensure_ascii=False, indent=2)}")
        return result
    else:
        print(f"错误响应: {response.text}")
        return None

def test_get_history(user_id):
    """测试获取历史记录接口"""
    print(f"\n=== 测试获取历史记录 ===")
    
    response = requests.get(f"{API_BASE_URL}/api/history/{user_id}")
    
    print(f"状态码: {response.status_code}")
    
    if response.status_code == 200:
        history = response.json()
        print(f"历史记录数量: {len(history)}")
        if history:
            print(f"最新记录: {json.dumps(history[0], ensure_ascii=False, indent=2)}")
        return history
    else:
        print(f"错误响应: {response.text}")
        return None

def main():
    """主测试流程"""
    print("🚀 开始端到端测试...")
    
    # 1. 测试登录
    user_id = test_login()
    if not user_id:
        print("❌ 登录测试失败，终止测试")
        return
    
    print(f"✅ 登录成功，用户ID: {user_id}")
    
    # 2. 测试图片分析
    test_images = [
        "static/images/0334f224-81fd-478d-b639-c4445397db9a.png",
        "static/images/157c2af8-4482-416d-8816-e746c50e1b96.png"
    ]
    
    analysis_results = []
    for image_path in test_images:
        result = test_analyze_image(user_id, image_path)
        if result:
            analysis_results.append(result)
            print(f"✅ 图片分析成功: {image_path}")
        else:
            print(f"❌ 图片分析失败: {image_path}")
    
    # 3. 测试历史记录
    history = test_get_history(user_id)
    if history is not None:
        print(f"✅ 历史记录获取成功，共 {len(history)} 条记录")
    else:
        print("❌ 历史记录获取失败")
    
    # 4. 性能测试
    print("\n=== 性能测试 ===")
    if test_images and os.path.exists(test_images[0]):
        import time
        start_time = time.time()
        test_analyze_image(user_id, test_images[0])
        end_time = time.time()
        response_time = end_time - start_time
        print(f"响应时间: {response_time:.2f}秒")
        
        if response_time < 10:
            print("✅ 性能测试通过（< 10秒）")
        else:
            print("⚠️ 性能测试警告（>= 10秒）")
    
    print("\n🎉 端到端测试完成！")

if __name__ == "__main__":
    main()