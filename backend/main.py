"""
LearnMind 后端 — FastAPI 主入口
AI个人学习知识系统 · Phase 1 MVP
"""
import sys
import os

# 将 backend 目录加入 Python 路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import knowledge, chat, review

app = FastAPI(
    title="LearnMind API",
    description="AI个人学习知识系统后端 API",
    version="1.0.0",
)

# CORS：允许 Flutter App 访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 开发环境，生产环境应限制具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(knowledge.router, prefix="/api/knowledge", tags=["知识卡片"])
app.include_router(chat.router, prefix="/api/chat", tags=["AI对话"])
app.include_router(review.router, prefix="/api/review", tags=["复习"])


@app.get("/")
async def root():
    return {"message": "LearnMind API 启动成功", "version": "1.0.0"}


@app.get("/api/health")
async def health():
    return {"status": "healthy"}


@app.get("/api/stats")
async def stats():
    """获取学习统计数据"""
    import sqlite3
    from datetime import datetime, timedelta
    from database import DB_PATH

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # 知识卡片总数
    cur.execute("SELECT COUNT(*) as total FROM knowledge_cards")
    total = cur.fetchone()["total"]

    # 今日待复习数
    today = datetime.now().strftime("%Y-%m-%d")
    cur.execute(
        "SELECT COUNT(*) as due FROM knowledge_cards WHERE date(next_review) <= ?",
        (today,),
    )
    due_today = cur.fetchone()["due"]

    # 本周新增
    week_ago = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
    cur.execute(
        "SELECT COUNT(*) as this_week FROM knowledge_cards WHERE date(created_at) >= ?",
        (week_ago,),
    )
    this_week = cur.fetchone()["this_week"]

    # 本周已完成复习次数
    cur.execute(
        "SELECT COUNT(*) as reviewed FROM review_logs WHERE date(reviewed_at) >= ?",
        (week_ago,),
    )
    reviewed = cur.fetchone()["reviewed"]

    conn.close()

    return {
        "total_cards": total,
        "due_today": due_today,
        "this_week_new": this_week,
        "this_week_reviewed": reviewed,
    }


@app.on_event("startup")
async def startup():
    init_db()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
