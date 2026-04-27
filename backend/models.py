"""
Pydantic 数据模型
定义所有请求/响应结构
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


# ── 知识卡片 ──────────────────────────────────────────

class SM2Data(BaseModel):
    easiness_factor: float = 2.5
    interval: int = 0
    repetitions: int = 0
    next_review: Optional[str] = None
    last_review: Optional[str] = None


class KnowledgeCardCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    tags: List[str] = []


class KnowledgeCardUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None


class KnowledgeCardResponse(BaseModel):
    id: str
    title: str
    content: str
    tags: List[str]
    created_at: str
    updated_at: str
    sm2_data: SM2Data


# ── AI 对话 ──────────────────────────────────────────

class ChatMessageInput(BaseModel):
    role: str  # "user" | "assistant"
    content: str


class ExplainRequest(BaseModel):
    card_id: str
    user_level: str = Field(default="中等", description="用户理解程度：入门/中等/进阶")
    custom_question: Optional[str] = Field(default=None, description="可选的自定义问题")


class FollowupRequest(BaseModel):
    card_id: str
    session_id: str
    message: str


class ChatResponse(BaseModel):
    session_id: str
    message: str
    explanation_depth: str = Field(default="中等", description="本次解释深度")


# ── 复习 ──────────────────────────────────────────

class ReviewSubmit(BaseModel):
    card_id: str
    quality: int = Field(..., ge=0, le=5, description="SM-2评分: 0-忘记~5-完美记住")


class ReviewQuestion(BaseModel):
    card_id: str
    question: str
    question_type: str  # "multiple_choice" | "short_answer"
    options: Optional[List[str]] = None  # 选择题选项
    answer: str


class ReviewQuestionResponse(BaseModel):
    card_id: str
    card_title: str
    questions: List[ReviewQuestion]
    session_id: str


class ReviewResultResponse(BaseModel):
    card_id: str
    correct: bool
    feedback: str
    next_review: str
    new_interval: int
    new_easiness_factor: float


# ── 统计 ──────────────────────────────────────────

class StatsResponse(BaseModel):
    total_cards: int
    due_today: int
    this_week_new: int
    this_week_reviewed: int
