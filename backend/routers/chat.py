"""
AI对话路由
POST /api/chat/explain   — AI讲解（单轮）
POST /api/chat/followup  — AI追问（多轮对话）
"""
import uuid
import json
from datetime import datetime
from fastapi import APIRouter, HTTPException
from database import get_conn
from models import ExplainRequest, FollowupRequest, ChatResponse
from services.openai_service import explain_concept, explain_followup

router = APIRouter()


def get_card_by_id(conn, card_id: str):
    """辅助：从数据库获取卡片"""
    cur = conn.cursor()
    cur.execute("SELECT * FROM knowledge_cards WHERE id = ?", (card_id,))
    return cur.fetchone()


@router.post("/explain", response_model=ChatResponse)
async def explain(req: ExplainRequest):
    """AI讲解一个知识卡片"""
    conn = get_conn()
    card = get_card_by_id(conn, req.card_id)
    conn.close()

    if not card:
        raise HTTPException(status_code=404, detail="知识卡片不存在")

    # 调用GPT-4o讲解
    explanation = explain_concept(
        title=card["title"],
        content=card["content"],
        user_level=req.user_level,
        focus=req.custom_question,
    )

    # 创建对话会话并保存
    session_id = str(uuid.uuid4())
    now = datetime.now().isoformat()
    conn = get_conn()
    cur = conn.cursor()

    cur.execute(
        "INSERT INTO chat_sessions (id, card_id, created_at) VALUES (?, ?, ?)",
        (session_id, req.card_id, now),
    )

    cur.execute(
        "INSERT INTO chat_messages (id, session_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), session_id, "user", req.custom_question or "请讲解这个概念", now),
    )

    cur.execute(
        "INSERT INTO chat_messages (id, session_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), session_id, "assistant", explanation, now),
    )

    conn.commit()
    conn.close()

    return ChatResponse(session_id=session_id, message=explanation)


@router.post("/followup", response_model=ChatResponse)
async def followup(req: FollowupRequest):
    """多轮追问——AI保持上下文"""
    conn = get_conn()

    # 验证卡片和会话存在
    card = get_card_by_id(conn, req.card_id)
    cur = conn.cursor()
    cur.execute(
        "SELECT * FROM chat_sessions WHERE id = ? AND card_id = ?",
        (req.session_id, req.card_id),
    )
    session = cur.fetchone()

    if not card or not session:
        conn.close()
        raise HTTPException(status_code=404, detail="卡片或会话不存在")

    # 获取历史对话
    cur.execute(
        "SELECT role, content FROM chat_messages WHERE session_id = ? ORDER BY created_at ASC",
        (req.session_id,),
    )
    history = [{"role": row["role"], "content": row["content"]} for row in cur.fetchall()]

    # 保存用户追问
    now = datetime.now().isoformat()
    cur.execute(
        "INSERT INTO chat_messages (id, session_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), req.session_id, "user", req.message, now),
    )
    conn.commit()
    conn.close()

    # 调用GPT-4o（带历史上下文）
    response = explain_followup(
        title=card["title"],
        content=card["content"],
        chat_history=history,
        user_message=req.message,
    )

    # 保存AI回复
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO chat_messages (id, session_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), req.session_id, "assistant", response, now),
    )
    conn.commit()
    conn.close()

    return ChatResponse(session_id=req.session_id, message=response)


@router.get("/history/{card_id}")
async def get_chat_history(card_id: str):
    """获取某个卡片的对话历史"""
    import sqlite3
    conn = get_conn()
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute(
        """
        SELECT s.id as session_id, m.role, m.content, m.created_at
        FROM chat_messages m
        JOIN chat_sessions s ON m.session_id = s.id
        WHERE s.card_id = ?
        ORDER BY m.created_at ASC
        """,
        (card_id,),
    )

    rows = cur.fetchall()
    conn.close()

    return [
        {
            "session_id": row["session_id"],
            "role": row["role"],
            "content": row["content"],
            "created_at": row["created_at"],
        }
        for row in rows
    ]
