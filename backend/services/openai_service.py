"""
OpenAI GPT-4o 服务封装
负责任务：AI讲解、多轮对话、题目生成、掌握度评估
"""
import os
import json
from openai import OpenAI
from typing import List, Dict, Optional

# 从环境变量读取 API Key（安全做法）
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.environ.get("OPENAI_BASE_URL", "")  # 可配置代理地址

# 初始化客户端
_client = None


def get_client() -> OpenAI:
    global _client
    if _client is None:
        _client = OpenAI(
            api_key=OPENAI_API_KEY,
            base_url=OPENAI_BASE_URL if OPENAI_BASE_URL else None,
        )
    return _client


# ── 系统提示词 ─────────────────────────────────────

EXPLAIN_SYSTEM_PROMPT = """你是一位耐心、专业的AI学习导师。

你的职责：
1. 清晰解释任何概念，用用户能理解的方式
2. 如果用户说"不太懂"，要用更简单的方式重新解释
3. 多用类比、例子、图解描述（文字版）帮助理解
4. 每次解释后，主动问"这样理解了吗？"

风格要求：
- 清晰简洁，避免过多专业术语
- 主动拆解复杂概念为简单步骤
- 鼓励用户继续提问，直到完全理解
"""

EXPLAIN_USER_PROMPT = """请讲解以下内容：

标题：{title}
内容：{content}

用户当前理解程度：{user_level}
{focus_hint}
"""

REVIEW_QUESTION_SYSTEM_PROMPT = """你是一位出题专家。根据知识卡片内容，生成高质量的复习题。

要求：
1. 题目要检验真正的理解，不能靠死记硬背
2. 选择题要有迷惑性选项（但不要钻牛角尖）
3. 简答题要有明确的评分标准
4. 题目语言简洁，选项清晰
5. 同时提供标准答案和评分要点

输出格式（严格JSON）：
{{
  "questions": [
    {{
      "type": "multiple_choice",
      "question": "题目内容",
      "options": ["A. 选项", "B. 选项", "C. 选项", "D. 选项"],
      "correct_answer": "B",
      "explanation": "为什么B正确"
    }},
    {{
      "type": "short_answer",
      "question": "题目内容",
      "sample_answer": "参考答案",
      "grading_tips": "评分要点"
    }}
  ]
}}"""


# ── 核心功能函数 ────────────────────────────────────


def explain_concept(
    title: str,
    content: str,
    user_level: str = "中等",
    focus: Optional[str] = None,
) -> str:
    """让AI讲解一个概念"""
    client = get_client()

    if not OPENAI_API_KEY:
        return "⚠️ OpenAI API Key 未配置。请在环境变量中设置 OPENAI_API_KEY"

    focus_hint = f"用户特别关注：{focus}" if focus else ""

    messages = [
        {"role": "system", "content": EXPLAIN_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": EXPLAIN_USER_PROMPT.format(
                title=title,
                content=content,
                user_level=user_level,
                focus_hint=focus_hint,
            ),
        },
    ]

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        temperature=0.7,
        max_tokens=1500,
    )

    return response.choices[0].message.content


def explain_followup(
    title: str,
    content: str,
    chat_history: List[Dict[str, str]],
    user_message: str,
) -> str:
    """多轮追问——AI保持上下文，理解用户卡在哪里"""
    client = get_client()

    if not OPENAI_API_KEY:
        return "⚠️ OpenAI API Key 未配置。"

    # 构建带上下文的对话
    messages = [
        {"role": "system", "content": EXPLAIN_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": f"以下是要讲解的内容：\n标题：{title}\n内容：{content}",
        },
    ]

    # 加入历史对话
    for msg in chat_history:
        messages.append({"role": msg["role"], "content": msg["content"]})

    # 加入当前追问
    messages.append({"role": "user", "content": user_message})

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        temperature=0.7,
        max_tokens=1000,
    )

    return response.choices[0].message.content


def generate_review_questions(title: str, content: str, num_questions: int = 2) -> dict:
    """AI生成复习题"""
    client = get_client()

    if not OPENAI_API_KEY:
        return {
            "questions": [
                {
                    "type": "multiple_choice",
                    "question": "⚠️ API未配置，请设置 OPENAI_API_KEY",
                    "options": [],
                    "correct_answer": "",
                    "explanation": "",
                }
            ]
        }

    prompt = f"""标题：{title}
内容：{content}

请生成 {num_questions} 道复习题。输出严格JSON格式："""

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": REVIEW_QUESTION_SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ],
        temperature=0.5,
        max_tokens=2000,
        response_format={"type": "json_object"},
    )

    raw = response.choices[0].message.content
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # 如果JSON解析失败，尝试提取JSON部分
        import re

        match = re.search(r"\{.*\}", raw, re.DOTALL)
        if match:
            return json.loads(match.group())
        return {"questions": []}


def evaluate_answer(
    question: str,
    user_answer: str,
    correct_answer: str,
    question_type: str,
) -> dict:
    """AI评估用户答题结果"""
    client = get_client()

    if not OPENAI_API_KEY:
        return {
            "correct": False,
            "feedback": "⚠️ API未配置",
            "quality_score": 0,
        }

    prompt = f"""题目：{question}
题型：{question_type}
正确答案：{correct_answer}
用户答案：{user_answer}

请评估用户答案是否正确，并给出反馈。

输出JSON格式：
{{
  "correct": true/false,
  "feedback": "反馈意见（指出对错原因）",
  "quality_score": 0-5（SM-2评分）
}}"""

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "system",
                "content": "你是一位严格的学习评估导师。评分要公正，0=完全错误，5=完美回答。",
            },
            {"role": "user", "content": prompt},
        ],
        temperature=0.3,
        max_tokens=500,
        response_format={"type": "json_object"},
    )

    try:
        return json.loads(response.choices[0].message.content)
    except json.JSONDecodeError:
        return {"correct": False, "feedback": "评估失败", "quality_score": 0}
