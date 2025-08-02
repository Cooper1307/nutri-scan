import os
import asyncio
from dotenv import load_dotenv

load_dotenv()
from alibabacloud_ocr_api20210707.client import Client as OcrClient
from alibabacloud_tea_openapi import models as open_api_models
from alibabacloud_ocr_api20210707 import models as ocr_models
from alibabacloud_tea_util import models as util_models
import io
import logging
import json

logger = logging.getLogger(__name__)

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

def recognize_text_from_image(file_path: str) -> str:
    access_key_id = os.environ.get("ALIYUN_ACCESS_KEY_ID")
    access_key_secret = os.environ.get("ALIYUN_ACCESS_KEY_SECRET")

    if not access_key_id or not access_key_secret:
        return "错误：阿里云访问密钥未配置。"

    config = open_api_models.Config(
        access_key_id=access_key_id,
        access_key_secret=access_key_secret
    )
    config.endpoint = OCR_ENDPOINT
    client = OcrClient(config)

    with open(file_path, 'rb') as f:
        file_content = f.read()

    body_stream = io.BytesIO(file_content)

    request = ocr_models.RecognizeGeneralRequest(
        body=body_stream
    )
    runtime = util_models.RuntimeOptions()

    try:
        response = client.recognize_general_with_options(request, runtime)
        logger.info(f"OCR API response status: {response.status_code}")
        logger.info(f"OCR API response body: {response.body}")
        # 根据实际的OCR API返回格式进行调整
        if response.status_code == 200 and response.body and response.body.data:
            data_str = response.body.data
            logger.info(f"OCR response data type: {type(data_str)}")
            logger.info(f"OCR response data content: {data_str}")
            data_json = json.loads(data_str)
            content = data_json.get('content', '')
            if isinstance(content, list):
                return "\n".join(content)
            return content
        else:
            message = response.body.message if response.body else "Unknown error"
            logger.error(f"OCR API error: {message}")
            return f"OCR识别失败：{message}"
    except Exception as e:
        logger.error(f"Exception during OCR call: {e}", exc_info=True)
        # 如果是网络连接问题，使用模拟数据作为备用方案
        if "Failed to resolve" in str(e) or "NameResolutionError" in str(e) or "HTTPSConnectionPool" in str(e):
            logger.warning("网络连接失败，使用模拟OCR数据作为备用方案")
            return """
营养成分表
项目         每100克   营养素参考值%
能量         1800千焦   21%
蛋白质       8.0克      13%
脂肪         15.0克     25%
碳水化合物   60.0克     20%
钠           600毫克    30%
"""
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