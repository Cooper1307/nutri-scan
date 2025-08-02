from pydantic import BaseModel
from typing import List, Literal

# 定义评估结果的类型
AssessmentType = Literal['green', 'yellow', 'red']

class NutrientDetail(BaseModel):
    name: str
    value: str
    nrv_percent: float
    assessment: AssessmentType

class AnalysisResult(BaseModel):
    overall_assessment: AssessmentType
    details: List[NutrientDetail]