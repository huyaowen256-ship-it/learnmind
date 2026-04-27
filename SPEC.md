# AI个人学习知识系统 — Phase 1 MVP 规格文档

## 1. 项目概述

- **项目名称**: LearnMind（学而思）
- **项目类型**: Flutter移动App + FastAPI后端
- **核心价值**: AI 1对1私教 + 知识管理 + 间隔复习闭环
- **目标用户**: 自主学习者，需要AI辅助理解 + 记忆强化的个人用户

## 2. 核心功能（Phase 1 MVP）

### F1: 知识卡片管理
- 添加知识卡片（标题 + 核心内容 + 标签/分类）
- 编辑/删除知识卡片
- 按标签筛选搜索
- 知识入库时自动提取关键概念（AI辅助）

### F2: AI讲解（核心功能）
- 选择任意知识卡片，一键让AI讲解
- AI讲解时考虑用户的理解程度调整深度
- 支持追问（多轮对话），直到用户说"懂了"
- 讲解历史保存，可回溯

### F3: 间隔复习（SM-2算法）
- 知识卡片按SM-2算法安排复习时间
- 复习时AI生成题目（选择题/简答题）
- 用户答题后AI评估并更新下次复习时间
- 每日复习提醒（本地通知）

### F4: 掌握度仪表盘
- 显示今日待复习数量
- 显示本周学习进度
- 掌握度评分（基于SM-2数据）

## 3. 技术架构

### 后端（FastAPI）
```
backend/
├── main.py              # FastAPI入口
├── database.py          # SQLite连接
├── models.py            # 数据模型（Pydantic）
├── services/
│   ├── openai_service.py   # GPT-4o调用封装
│   ├── sm2_service.py      # SM-2间隔重复算法
│   └── review_service.py   # 复习调度服务
└── routers/
    ├── knowledge.py     # 知识卡片CRUD
    ├── chat.py          # AI对话接口
    └── review.py        # 复习接口
```

### 移动端（Flutter）
```
learnmind_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── knowledge_card.dart
│   │   └── review_item.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   └── notification_service.dart
│   ├── providers/
│   │   ├── knowledge_provider.dart
│   │   └── review_provider.dart
│   └── screens/
│       ├── home_screen.dart
│       ├── knowledge_list_screen.dart
│       ├── knowledge_detail_screen.dart
│       ├── chat_screen.dart
│       └── review_screen.dart
```

## 4. 数据模型

### KnowledgeCard
```python
{
    "id": str,               # UUID
    "title": str,            # 标题
    "content": str,          # 核心内容
    "tags": List[str],      # 标签
    "created_at": datetime,
    "updated_at": datetime,
    "sm2_data": {            # SM-2复习数据
        "easiness_factor": float,  # 默认2.5
        "interval": int,          # 间隔天数
        "repetitions": int,       # 重复次数
        "next_review": datetime,  # 下次复习时间
        "last_review": datetime
    }
}
```

### ChatMessage
```python
{
    "card_id": str,
    "messages": [
        {"role": "user", "content": str},
        {"role": "assistant", "content": str}
    ],
    "created_at": datetime
}
```

## 5. API接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/knowledge | 获取所有知识卡片 |
| POST | /api/knowledge | 新增知识卡片 |
| GET | /api/knowledge/{id} | 获取单个卡片 |
| PUT | /api/knowledge/{id} | 更新卡片 |
| DELETE | /api/knowledge/{id} | 删除卡片 |
| POST | /api/chat/explain | AI讲解（单轮） |
| POST | /api/chat/followup | AI追问（多轮） |
| GET | /api/review/today | 获取今日待复习 |
| POST | /api/review/submit | 提交复习结果 |
| GET | /api/stats | 获取学习统计 |

## 6. 验收标准（闭环数据）

- [ ] 能添加知识卡片到本地SQLite
- [ ] 能让GPT-4o讲解任意知识卡片
- [ ] 能追问至少3轮，AI保持上下文
- [ ] SM-2算法正确计算下次复习时间
- [ ] 复习题目由AI生成，不是固定题库
- [ ] App UI流畅，操作闭环

## 7. 依赖版本

| 组件 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.19+ | 移动端框架 |
| Dart | 3.3+ | Flutter语言 |
| Python | 3.11+ | 后端语言 |
| FastAPI | 0.110+ | Web框架 |
| SQLite | 3.x | 本地数据库 |
| openai | 1.12+ | OpenAI SDK |
| flutter_riverpod | 2.5+ | 状态管理 |
