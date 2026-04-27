"""
复习路由
GET  /api/review/today           — 获取今日待复习卡片
POST /api/review/questions/{card_id}  — 生成复习题
POST /api/review/submit          — 提交复习结果
"""
import sqlite3
from fastapi import APIRouter, HTTPException
from database import get_conn
from models import ReviewSubmit, ReviewResultResponse
from services.review_service import (
    get_due_cards,
    generate_review_for_card,
    submit_review,
)

router = APIRouter()


@router.get("/today")
async def get_today_reviews():
    """获取今日待复习的知识卡片"""
    cards = get_due_cards()
    return {
        "count": len(cards),
        "cards": cards,
    }


@router.get("/questions/{card_id}")
async def get_review_questions(card_id: str):
    """为指定卡片生成复习题"""
    conn = get_conn()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute("SELECT id FROM knowledge_cards WHERE id = ?", (card_id,))
    if not cur.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="卡片不存在")
    conn.close()

    result = generate_review_for_card(card_id)
    return result


@router.post("/submit", response_model=ReviewResultResponse)
async def submit_review_result(submit: ReviewSubmit):
    """提交复习结果（用户自评质量 0-5）"""
    conn = get_conn()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute("SELECT id FROM knowledge_cards WHERE id = ?", (submit.card_id,))
    if not cur.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="卡片不存在")
    conn.close()

    result = submit_review(submit.card_id, submit.quality)
    return ReviewResultResponse(
        card_id=result["card_id"],
        correct=result["correct"],
        feedback=result["feedback"],
        next_review=result["next_review"],
        new_interval=result["new_interval"],
        new_easiness_factor=result["new_easiness_factor"],
    )
