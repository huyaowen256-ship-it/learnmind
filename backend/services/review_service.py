"""
复习调度服务
负责生成复习题目、提交复习结果、更新SM-2数据
"""
import uuid
import json
from datetime import datetime
from database import get_conn
from models import ReviewQuestion
from services.openai_service import generate_review_questions, evaluate_answer
from services.sm2_service import calculate_sm2, get_next_review_date


def get_due_cards(limit: int = 10):
    """获取今日待复习的知识卡片"""
    conn = get_conn()
    cur = conn.cursor()

    today = datetime.now().strftime("%Y-%m-%d")
    cur.execute(
        """
        SELECT id, title, content, tags, sm2_data,
               easiness_factor, interval, repetitions, next_review, last_review
        FROM knowledge_cards
        WHERE next_review IS NULL OR date(next_review) <= ?
        ORDER BY COALESCE(next_review, created_at) ASC
        LIMIT ?
        """,
        (today, limit),
    )

    rows = cur.fetchall()
    conn.close()

    cards = []
    for row in rows:
        cards.append(
            {
                "id": row["id"],
                "title": row["title"],
                "content": row["content"],
                "tags": json.loads(row["tags"]) if row["tags"] else [],
                "sm2_data": {
                    "easiness_factor": row["easiness_factor"],
                    "interval": row["interval"],
                    "repetitions": row["repetitions"],
                    "next_review": row["next_review"],
                    "last_review": row["last_review"],
                },
            }
        )
    return cards


def generate_review_for_card(card_id: str, num_questions: int = 2) -> dict:
    """为指定卡片生成复习题"""
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT title, content FROM knowledge_cards WHERE id = ?", (card_id,))
    row = cur.fetchone()
    conn.close()

    if not row:
        return {"card_id": card_id, "error": "卡片不存在"}

    # 调用AI生成题目
    result = generate_review_questions(row["title"], row["content"], num_questions)
    session_id = str(uuid.uuid4())

    questions = []
    for q in result.get("questions", []):
        questions.append(
            ReviewQuestion(
                card_id=card_id,
                question=q.get("question", ""),
                question_type=q.get("type", "short_answer"),
                options=q.get("options"),
                answer=q.get(
                    "correct_answer", q.get("sample_answer", "")
                ),
            ).model_dump()
        )

    return {
        "card_id": card_id,
        "card_title": row["title"],
        "questions": questions,
        "session_id": session_id,
    }


def submit_review(card_id: str, quality: int, user_answer: str = None) -> dict:
    """
    提交复习结果，更新SM-2数据
    """
    conn = get_conn()
    cur = conn.cursor()

    # 获取当前SM-2数据
    cur.execute(
        "SELECT easiness_factor, interval, repetitions FROM knowledge_cards WHERE id = ?",
        (card_id,),
    )
    row = cur.fetchone()
    if not row:
        conn.close()
        return {"error": "卡片不存在"}

    ef, interval, reps = (
        row["easiness_factor"],
        row["interval"],
        row["repetitions"],
    )

    # SM-2计算
    new_ef, new_interval, new_reps = calculate_sm2(quality, ef, interval, reps)
    next_review = get_next_review_date(new_interval)

    # 更新卡片SM-2数据
    now = datetime.now().isoformat()
    cur.execute(
        """
        UPDATE knowledge_cards
        SET easiness_factor = ?,
            interval = ?,
            repetitions = ?,
            next_review = ?,
            last_review = ?
        WHERE id = ?
        """,
        (new_ef, new_interval, new_reps, next_review, now, card_id),
    )

    # 记录复习日志
    log_id = str(uuid.uuid4())
    cur.execute(
        "INSERT INTO review_logs (id, card_id, quality, reviewed_at, next_interval) VALUES (?, ?, ?, ?, ?)",
        (log_id, card_id, quality, now, new_interval),
    )

    conn.commit()
    conn.close()

    return {
        "card_id": card_id,
        "correct": quality >= 3,
        "feedback": _get_feedback_message(quality),
        "next_review": next_review,
        "new_interval": new_interval,
        "new_easiness_factor": new_ef,
    }


def _get_feedback_message(quality: int) -> str:
    """生成复习反馈"""
    messages = {
        0: "完全忘记啦，不要紧，重新开始复习～",
        1: "有点印象但想不起来，下次继续努力！",
        2: "快要想起来了，继续保持！",
        3: "正确！有些犹豫，建议再复习一遍。",
        4: "正确！掌握得不错。",
        5: "完美！你已经完全掌握了！🎉",
    }
    return messages.get(quality, "复习完成，继续加油！")
