from fastapi import APIRouter, File, UploadFile, HTTPException, Request
from app.services.ocr_service import recognize_text_from_image
from app.services.wechat_service import get_user_openid
from app.logic.analyzer import parse_nutrition_info, analyze_nutrients
import os
import uuid
from pydantic import BaseModel

class LoginPayload(BaseModel):
    code: str

router = APIRouter()

# 确保静态文件目录存在
STATIC_DIR = "static/images"
os.makedirs(STATIC_DIR, exist_ok=True)

@router.post("/login", summary="微信登录")
async def login(payload: LoginPayload):
    """
    接收前端发送的 code，换取 openid。
    """
    try:
        user_data = await get_user_openid(payload.code)
        # 在实际应用中，您会在这里创建或更新用户信息到数据库
        # 并生成一个自定义的登录令牌（token）返回给前端
        return {"openid": user_data.get("openid"), "message": "Login successful"}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")

@router.post("/analyze")
async def analyze_image(request: Request, file: UploadFile = File(...)):
    """
    接收上传的图片文件，进行OCR识别和营养分析。
    """
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Uploaded file is not an image.")

    try:
        # 生成唯一文件名并保存图片
        file_extension = os.path.splitext(file.filename)[1]
        filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(STATIC_DIR, filename)
        
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())

        # 构建可访问的图片URL
        # 注意：这需要你在FastAPI应用中配置了静态文件服务
        image_url = f"{request.base_url}{file_path}"

        # 1. 调用OCR服务获取文本
        ocr_text = await recognize_text_from_image(image_url)
        
        # 2. 解析文本中的营养信息
        parsed_info = parse_nutrition_info(ocr_text)
        if not parsed_info:
            raise HTTPException(status_code=422, detail="Could not parse nutrition info from image.")

        # 3. 分析营养信息并返回结果
        analysis_result = analyze_nutrients(parsed_info)
        
        return analysis_result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")
    finally:
        # 清理临时文件
        if os.path.exists(file_path):
            os.remove(file_path)