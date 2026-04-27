"""
知识卡片 CRUD 路由
POST /api/knowledge          — 新增
GET  /api/knowledge          — 列表（支持搜索）
GET  /api/knowledge/{id}     — 详情
PUT  /api/knowledge/{id}     — 更新
DELETE /api/knowledge/{id}   — 删除
"""
import uuid
import json
import sqlite3
from datetime import datetime
from fastapi import APIRouter, HTTPException
from database import get_conn
from models import (
    KnowledgeCardCreate,
    KnowledgeCardUpdate,
    KnowledgeCardResponse,
    SM2Data,
)

router = APIRouter()


@router.post("", response_model=KnowledgeCardResponse, status_code=201)
async def create_card(card: KnowledgeCardCreate):
    """新增知识卡片"""
    conn = get_conn()
    cur = conn.cursor()

    card_id = str(uuid.uuid4())
    now = datetime.now().isoformat()

    try:
        cur.execute(
            """
            INSERT INTO knowledge_cards (id, title, content, tags, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (card_id, card.title, card.content, json.dumps(card.tags), now, now),
        )
        conn.commit()
    except Exception as e:
        conn.close()
        raise HTTPException(status_code=400, detail=str(e))

    conn.close()
    return KnowledgeCardResponse(
        id=card_id,
        title=card.title,
        content=card.content,
        tags=card.tags,
        created_at=now,
        updated_at=now,
        sm2_data=SM2Data(),
    )


@router.get("", response_model=list[KnowledgeCardResponse])
async def list_cards(q: str = "", tag: str = ""):
    """
    获取知识卡片列表
    q: 关键词搜索（模糊匹配标题和内容）
    tag: 按标签过滤
    """
    conn = get_conn()
    conn.row_factory = sqlite3.Row  # noqa: F811
    cur = conn.cursor()

    if q:
        # 使用 FTS5 全文搜索
        cur.execute(
            """
            SELECT k.* FROM knowledge_cards k
            JOIN knowledge_fts fts ON k.rowid = fts.rowid
            WHERE knowledge_fts MATCH ?
            ORDER BY k.created_at DESC
            """,
            (f"{q}*",),
        )
    else:
        cur.execute("SELECT * FROM knowledge_cards ORDER BY created_at DESC")

    rows = cur.fetchall()
    conn.close()

    cards = []
    for row in rows:
        tags = json.loads(row["tags"]) if row["tags"] else []

        # 标签过滤
        if tag and tag not in tags:
            continue

        cards.append(
            KnowledgeCardResponse(
                id=row["id"],
                title=row["title"],
                content=row["content"],
                tags=tags,
                created_at=row["created_at"],
                updated_at=row["updated_at"],
                sm2_data=SM2Data(
                    easiness_factor=row["easiness_factor"],
                    interval=row["interval"],
                    repetitions=row["repetitions"],
                    next_review=row["next_review"],
                    last_review=row["last_review"],
                ),
            )
        )
    return cards


@router.get("/{card_id}", response_model=KnowledgeCardResponse)
async def get_card(card_id: str):
    """获取单个知识卡片详情"""
    conn = get_conn()
    conn.row_factory = sqlite3.Row  # noqa: F811
    cur = conn.cursor()
    cur.execute("SELECT * FROM knowledge_cards WHERE id = ?", (card_id,))
    row = cur.fetchone()
    conn.close()

    if not row:
        raise HTTPException(status_code=404, detail="卡片不存在")

    return KnowledgeCardResponse(
        id=row["id"],
        title=row["title"],
        content=row["content"],
        tags=json.loads(row["tags"]) if row["tags"] else [],
        created_at=row["created_at"],
        updated_at=row["updated_at"],
        sm2_data=SM2Data(
            easiness_factor=row["easiness_factor"],
            interval=row["interval"],
            repetitions=row["repetitions"],
            next_review=row["next_review"],
            last_review=row["last_review"],
        ),
    )


@router.put("/{card_id}", response_model=KnowledgeCardResponse)
async def update_card(card_id: str, card: KnowledgeCardUpdate):
    """更新知识卡片"""
    conn = get_conn()
    cur = conn.cursor()

    # 检查存在
    cur.execute("SELECT * FROM knowledge_cards WHERE id = ?", (card_id,))
    existing = cur.fetchone()
    if not existing:
        conn.close()
        raise HTTPException(status_code=404, detail="卡片不存在")

    now = datetime.now().isoformat()
    title = card.title if card.title is not None else existing["title"]
    content = card.content if card.content is not None else existing["content"]
    tags = card.tags if card.tags is not None else json.loads(
        existing["tags"] or "[]"
    )

    cur.execute(
        """
        UPDATE knowledge_cards
        SET title = ?, content = ?, tags = ?, updated_at = ?
        WHERE id = ?
        """,
        (title, content, json.dumps(tags), now, card_id),
    )
    conn.commit()
    conn.close()

    return KnowledgeCardResponse(
        id=card_id,
        title=title,
        content=content,
        tags=tags,
        created_at=existing["created_at"],
        updated_at=now,
        sm2_data=SM2Data(
            easiness_factor=existing["easiness_factor"],
            interval=existing["interval"],
            repetitions=existing["repetitions"],
            next_review=existing["next_review"],
            last_review=existing["last_review"],
        ),
    )


@router.delete("/{card_id}", status_code=204)
async def delete_card(card_id: str):
    """删除知识卡片"""
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id FROM knowledge_cards WHERE id = ?", (card_id,))
    if not cur.fetchone():
        conn.close()
        raise HTTPException(status_code=404, detail="卡片不存在")

    cur.execute("DELETE FROM knowledge_cards WHERE id = ?", (card_id,))
    conn.commit()
    conn.close()
    return None


