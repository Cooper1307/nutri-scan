from fastapi import APIRouter, File, UploadFile, HTTPException, Request, Depends, Body, Form
from sqlalchemy.orm import Session
from typing import List

from .. import crud, models, schemas
from ..database import SessionLocal
from app.services.ocr_service import recognize_text_from_image
from app.services.wechat_service import get_user_openid
from app.logic.analyzer import parse_nutrition_info, analyze_nutrients
import os
import uuid
import logging
from pydantic import BaseModel

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
        # 测试模式：如果code以test_开头，则使用模拟数据
        if payload.code.startswith("test_"):
            openid = f"test_openid_{payload.code}"
            logger.info(f"Test mode: using mock openid {openid}")
        else:
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
def analyze_image(request: Request, file: UploadFile = File(...), user_id: str = Form(...), db: Session = Depends(get_db)):
    logger.info(f"Received request for /analyze for user_id: {user_id}")
    
    # 安全检查：验证文件类型
    if not file.content_type or not file.content_type.startswith('image/'):
        logger.warning(f"Uploaded file is not an image: {file.content_type}")
        raise HTTPException(status_code=400, detail="Uploaded file is not an image.")

    try:
        file_extension = os.path.splitext(file.filename)[1]
        filename = f"{uuid.uuid4()}{file_extension}"
        file_path = os.path.join(STATIC_DIR, filename)
        logger.info(f"Saving uploaded image to: {file_path}")

        file_content = file.file.read()
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)
        logger.info("Image saved successfully.")

        image_url = f"{str(request.base_url).strip('/')}/static/images/{filename}"
        logger.info(f"Image URL: {image_url}")

        logger.info("Calling OCR service...")
        ocr_text_raw = recognize_text_from_image(file_path)
        if isinstance(ocr_text_raw, bytes):
            ocr_text = ocr_text_raw.decode('utf-8', errors='ignore')
        else:
            ocr_text = ocr_text_raw
        logger.info(f"OCR service returned text: {ocr_text[:100]}...")

        logger.info("Parsing nutrition info...")
        parsed_info = parse_nutrition_info(ocr_text)
        if not parsed_info:
            logger.error("Failed to parse nutrition info from OCR text.")
            raise HTTPException(status_code=422, detail="Could not parse nutrition info from image.")
        logger.info(f"Parsed nutrition info: {parsed_info}")

        logger.info("Analyzing nutrients...")
        analysis_result = analyze_nutrients(parsed_info)
        logger.info("Nutrient analysis successful.")

        logger.info("Saving analysis to history...")
        import json
        history_data = schemas.AnalysisHistoryCreate(
            image_url=image_url,
            result_json=json.dumps(analysis_result, ensure_ascii=False)
        )
        crud.create_analysis_history(db=db, history=history_data, user_id=user_id)
        logger.info("Analysis saved to history successfully.")

        return analysis_result

    except HTTPException as e:
        logger.error(f"HTTPException in /analyze: {e.detail}")
        raise e
    except Exception as e:
        logger.error(f"An unexpected error occurred in /analyze: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")
    finally:
        # For simplicity, we are not cleaning up the image file to be able to show it in history.
        # In a real application, you might want to have a better strategy for this.
        pass

@router.get("/history/{user_id}", response_model=List[schemas.AnalysisHistory])
def read_history(user_id: str, skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    history = crud.get_analysis_history_by_user(db, user_id=user_id, skip=skip, limit=limit)
    return history