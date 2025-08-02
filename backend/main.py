import re
from typing import List, Optional
from fastapi import FastAPI, File, UploadFile
from pydantic import BaseModel

# --- Pydantic 模型定义 ---
class NutrientItem(BaseModel):
    name: str
    value: str
    unit: str
    nrv_percent: float
    rating: str  # 'high', 'medium', 'low'
    friendly_name: str
    advice: str

class AnalysisResponse(BaseModel):
    nutrients: List[NutrientItem]
    summary: Optional[str] = None

# --- FastAPI 应用实例 ---
app = FastAPI(
    title="老年人营养健康小程序后端",
    description="提供食品营养成分OCR分析服务。",
    version="1.0.0",
)

# --- 模拟OCR服务 ---
def mock_ocr_service(image_bytes: bytes) -> str:
    """
    模拟第三方OCR服务。
    忽略输入的图片，直接返回一个硬编码的营养成分表示例字符串。
    """
    # 模拟一个典型的营养成分表OCR识别结果
    return """
    营养成分表
    项目         每100克    营养素参考值%
    能量         1963千焦   23%
    蛋白质       6.8克      11%
    脂肪         22.5克     38%
    - 反式脂肪   0克
    碳水化合物   62.5克     21%
    钠           709毫克    35%
    """

# --- 核心分析逻辑 ---
def analyze_nutrition_text(text: str) -> AnalysisResponse:
    """
    解析OCR文本，提取营养信息，并根据规则进行评估。
    """
    nutrients = []

    # 定义我们要查找的营养素和它们的规则
    # (正则表达式, 通俗名称, 单位)
    targets = {
        "脂肪": (r"脂肪\s*([\d\.]+)\s*克\s*(\d+)", "油", "克"),
        "碳水化合物": (r"碳水化合物\s*([\d\.]+)\s*克\s*(\d+)", "糖", "克"),
        "钠": (r"钠\s*([\d\.]+)\s*毫克\s*(\d+)", "盐", "毫克"),
    }

    for name, (pattern, friendly_name, unit) in targets.items():
        match = re.search(pattern, text)
        if match:
            value_str, nrv_str = match.groups()
            value = float(value_str)
            nrv = int(nrv_str)

            rating = ""
            advice = ""
            if nrv > 20:
                rating = "high"
                advice = f"这份食品的{friendly_name}含量有点高哦，要注意！"
            elif nrv >= 5:
                rating = "medium"
                advice = f"这份食品的{friendly_name}含量适中。"
            else:
                rating = "low"
                advice = f"这份食品的{friendly_name}含量很低，不错！"

            nutrients.append(NutrientItem(
                name=name,
                value=str(value),
                unit=unit,
                nrv_percent=nrv,
                rating=rating,
                friendly_name=friendly_name,
                advice=advice
            ))

    summary = "总体来说，请注意油、糖、盐的摄入量。" if any(n.rating == 'high' for n in nutrients) else "总体来看，这份食品的各项指标都在合理范围。"

    return AnalysisResponse(nutrients=nutrients, summary=summary)

# --- API 端点 ---
@app.get("/")
def read_root():
    return {"message": "Welcome to the Elderly Health Nutrition Mini-Program API"}

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_image(file: UploadFile = File(...)):
    """
    接收上传的图片文件，进行OCR分析并返回结构化数据。

    - **第一步**: (模拟)调用OCR服务识别图片中的文字。
    - **第二步**: 解析文字，提取关键营养成分。
    - **第三步**: 根据NRV%评估营养成分水平。
    - **第四步**: 返回结构化的JSON结果。
    """
    image_bytes = await file.read()

    # 1. 调用OCR服务 (当前为模拟)
    ocr_text = mock_ocr_service(image_bytes)

    # 2. 分析文本并返回结果
    analysis_result = analyze_nutrition_text(ocr_text)

    return analysis_result