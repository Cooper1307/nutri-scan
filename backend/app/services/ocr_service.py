import os
import asyncio
from aliyunsdkcore import client
from aliyunsdkgreen.request.v20180509 import ImageSyncScanRequest
import json
import uuid

# --- 配置说明 ---
# 1. 前往阿里云控制台 (https://ram.console.aliyun.com/users) 创建一个RAM用户，并为其创建AccessKey。
# 2. 为该RAM用户授予 AliyunOCRFullAccess 权限。
# 3. 在您的开发环境中设置以下两个环境变量，出于安全考虑，切勿将AccessKey硬编码在代码中。
#    - ALIYUN_ACCESS_KEY_ID
#    - ALIYUN_ACCESS_KEY_SECRET
#
# 设置环境变量示例 (在Windows PowerShell中):
# $env:ALIYUN_ACCESS_KEY_ID="YourAccessKeyId"
# $env:ALIYUN_ACCESS_KEY_SECRET="YourAccessKeySecret"
#
# 验证环境变量是否设置成功:
# echo $env:ALIYUN_ACCESS_KEY_ID

ACCESS_KEY_ID = os.environ.get("ALIYUN_ACCESS_KEY_ID")
ACCESS_KEY_SECRET = os.environ.get("ALIYUN_ACCESS_KEY_SECRET")
# OCR API的地域接入点，请根据您的位置选择，例如华东（上海）为 ocr-cn-shanghai.aliyuncs.com
OCR_ENDPOINT = "ocr-cn-shanghai.aliyuncs.com"

if not all([ACCESS_KEY_ID, ACCESS_KEY_SECRET]):
    raise ValueError("环境变量 ALIYUN_ACCESS_KEY_ID 和 ALIYUN_ACCESS_KEY_SECRET 未设置")

async def recognize_text_from_image(image_url: str) -> str:
    access_key_id = os.environ.get("ALIYUN_ACCESS_KEY_ID")
    access_key_secret = os.environ.get("ALIYUN_ACCESS_KEY_SECRET")

    if not access_key_id or not access_key_secret:
        return "错误：阿里云访问密钥未配置。"

    clt = client.AcsClient(access_key_id, access_key_secret, "cn-shanghai")
    
    request = ImageSyncScanRequest.ImageSyncScanRequest()
    request.set_accept_format('JSON')

    task = {
        "dataId": str(uuid.uuid1()),
        "url": image_url
    }

    request.set_content(json.dumps({"tasks": [task], "scenes": ["ocr"]}).encode("utf-8"))

    try:
        response = clt.do_action_with_exception(request)
        result = json.loads(response)
        if 200 == result.get("code"):
            task_results = result.get("data", [])
            for task_result in task_results:
                if 200 == task_result.get("code"):
                    scene_results = task_result.get("results", [])
                    #  此处可以根据需要进一步解析 scene_results
                    return json.dumps(scene_results, ensure_ascii=False)
        return f"OCR识别失败: {response}"
    except Exception as e:
        return f"OCR识别失败：{e}" 

async def recognize_text_from_image_mock(image_bytes: bytes) -> str:
    """
    模拟OCR识别，保留用于快速测试或在没有网络连接时使用。
    """
    await asyncio.sleep(0.1)
    return """
    营养成分表
    项目         每100克   营养素参考值%
    能量         1800千焦   21%
    蛋白质       8.0克      13%
    脂肪         15.0克     25%
    碳水化合物   60.0克     20%
    钠           600毫克    30%
    """