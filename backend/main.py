from fastapi import FastAPI, File, UploadFile

app = FastAPI(
    title="老年人营养健康小程序后端",
    description="提供食品营养成分OCR分析服务。",
    version="1.0.0",
)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Elderly Health Nutrition Mini-Program API"}


@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)):
    """
    接收上传的图片文件，进行OCR分析并返回结构化数据。
    (当前为桩代码，仅返回文件名)
    """
    # 在这里将添加调用OCR服务和分析逻辑
    return {"filename": file.filename, "content_type": file.content_type}