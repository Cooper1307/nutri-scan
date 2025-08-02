from sqlalchemy.orm import Session
from . import models, schemas

def get_user_by_openid(db: Session, openid: str):
    return db.query(models.User).filter(models.User.openid == openid).first()

def create_user(db: Session, openid: str):
    db_user = models.User(id=f"user_{openid}", openid=openid)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_analysis_history(
    db: Session, history: schemas.AnalysisHistoryCreate, user_id: str
):
    db_history = models.AnalysisHistory(**history.dict(), user_id=user_id)
    db.add(db_history)
    db.commit()
    db.refresh(db_history)
    return db_history

def get_analysis_history_by_user(db: Session, user_id: str, skip: int = 0, limit: int = 10):
    return (
        db.query(models.AnalysisHistory)
        .filter(models.AnalysisHistory.user_id == user_id)
        .order_by(models.AnalysisHistory.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )