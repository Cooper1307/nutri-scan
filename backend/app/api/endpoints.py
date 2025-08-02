from fastapi import APIRouter, File, UploadFile, HTTPException, Request, Depends, Body
from sqlalchemy.orm import Session
from typing import List

from .. import crud, models, schemas
from ..database import SessionLocal
from app.services.ocr_service import recognize_text_from_image
from app.services.wechat_service import get_user_openid
from app.logic.analyzer import parse_nutrition_info, analyze_nutrients
import os
import uuid
from pydantic import BaseModel

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class LoginPayload(BaseModel):
    code: str

router = APIRouter()

# 确保静态文件目录存在
STATIC_DIR = "static/images"
os.makedirs(STATIC_DIR, exist_ok=True)

@router.post("/login", summary="微信登录")
def login(payload: LoginPayload, db: Session = Depends(get_db)):
    """
    接收前端发送的 code，换取 openid，并创建或获取用户。
    """
    try:
        user_data = get_user_openid(payload.code)
        openid = user_data.get("openid")
        if not openid:
            raise HTTPException(status_code=400, detail="Invalid code")

        db_user = crud.get_user_by_openid(db, openid=openid)
        if not db_user:
            db_user = crud.create_user(db, openid=openid)
        
        return {"openid": db_user.openid, "user_id": db_user.id}
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")

@router.post("/analyze")
async def analyze_image(request: Request, file: UploadFile = File(...), user_id: str = Body(...), db: Session = Depends(get_db)):
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

        # Save to history
        history_data = schemas.AnalysisHistoryCreate(
            image_url=image_url,
            result_json=analysis_result
        )
        crud.create_analysis_history(db=db, history=history_data, user_id=user_id)
        
        return analysis_result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")
    finally:
        # For simplicity, we are not cleaning up the image file to be able to show it in history.
        # In a real application, you might want to have a better strategy for this.
        pass

@router.get("/history/{user_id}", response_model=List[schemas.AnalysisHistory])
def read_history(user_id: str, skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    history = crud.get_analysis_history_by_user(db, user_id=user_id, skip=skip, limit=limit)
    return history