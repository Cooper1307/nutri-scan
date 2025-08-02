from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional

# 用于创建新的分析历史记录
class AnalysisHistoryBase(BaseModel):
    image_url: str
    result_json: dict

class AnalysisHistoryCreate(AnalysisHistoryBase):
    pass

# 用于从数据库读取分析历史记录
class AnalysisHistory(AnalysisHistoryBase):
    id: int
    user_id: str
    created_at: datetime

    class Config:
        orm_mode = True

# 用于展示用户及其历史记录
class User(BaseModel):
    id: str
    openid: str
    created_at: datetime
    updated_at: Optional[datetime]
    analysis_history: List[AnalysisHistory] = []

    class Config:
        orm_mode = True