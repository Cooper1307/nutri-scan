from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import uvicorn
from app.api.endpoints import router as api_router
from app.database import engine, Base
import os

# 在应用启动时创建数据库表
@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="营养健康小程序后端",
    description="提供OCR识别和营养成分分析服务。",
    version="1.1.0",
)

# 确保静态目录存在
STATIC_DIR = "static"
os.makedirs(STATIC_DIR, exist_ok=True)

# 挂载静态文件目录
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

@app.get("/", tags=["General"], summary="服务健康检查")
def health_check():
    """
    执行一个简单的健康检查，如果服务正常运行，则返回成功消息。
    """
    return {"status": "ok", "message": "服务运行正常"}

app.include_router(api_router, prefix="/api", tags=["Analysis"])

if __name__ == "__main__":
    # 启动服务，监听在 8000 端口
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)