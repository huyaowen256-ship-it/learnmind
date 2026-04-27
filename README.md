# LearnMind - 个人学习系统

AI 驱动的个人知识管理与间隔重复复习系统。

```
Flutter (Android/iOS) + FastAPI (Python) + SQLite + GPT-4o
```

## 功能特性

| 模块 | 说明 |
|------|------|
| **知识卡片** | 创建/编辑/删除，标签管理，全文搜索 (FTS5) |
| **AI 讲解** | 选卡 → GPT-4o 智能解释，支持追问跟进 |
| **间隔复习** | SM-2 算法驱动，AI 生成题目，每日复习提醒 |
| **数据统计** | 知识库总量、待复习数、本周新增/复习数 |

## 快速开始

### 后端

```bash
cd backend

# 安装依赖
pip install -r requirements.txt

# 配置 API Key（可选，默认使用 GPT-4o）
export OPENAI_API_KEY=sk-...

# 启动服务
python main.py
# → http://localhost:8000
```

### Flutter App

```bash
cd learnmind_app

flutter pub get
flutter run
```

> 模拟器连接后端：`http://10.0.2.2:8000/api`
> 真机连接：局域网 IP + `--dart-define=API_BASE=http://192.168.x.x:8000/api`

## 项目结构

```
learnmind_app/
├── lib/
│   ├── models/       # 数据模型
│   ├── providers/    # Riverpod 状态管理
│   ├── screens/      # 页面 UI
│   ├── services/     # API 调用层
│   └── widgets/      # 公共组件
backend/
├── routers/          # FastAPI 路由
├── services/         # 业务逻辑（SM-2 / OpenAI）
├── models.py         # Pydantic 模型
├── database.py       # SQLite 初始化
└── main.py           # 应用入口
```

## 技术栈

- **前端**：Flutter + Riverpod
- **后端**：FastAPI + Uvicorn
- **数据库**：SQLite (FTS5 全文搜索)
- **AI**：OpenAI GPT-4o API
- **算法**：SM-2 间隔重复