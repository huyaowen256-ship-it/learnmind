"""
数据库初始化与连接
SQLite 本地存储 · Phase 1 MVP
"""
import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "learnmind.db")


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # 可以用列名访问
    return conn


def init_db():
    """初始化数据库表结构"""
    conn = get_conn()
    cur = conn.cursor()

    # 知识卡片表
    cur.execute("""
        CREATE TABLE IF NOT EXISTS knowledge_cards (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT DEFAULT '[]',          -- JSON数组
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            -- SM-2 间隔重复数据
            easiness_factor REAL DEFAULT 2.5,
            interval INTEGER DEFAULT 0,
            repetitions INTEGER DEFAULT 0,
            next_review TEXT,                -- ISO格式时间
            last_review TEXT
        )
    """)

    # AI对话历史表
    cur.execute("""
        CREATE TABLE IF NOT EXISTS chat_sessions (
            id TEXT PRIMARY KEY,
            card_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (card_id) REFERENCES knowledge_cards(id) ON DELETE CASCADE
        )
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS chat_messages (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            role TEXT NOT NULL,              -- 'user' or 'assistant'
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
        )
    """)

    # 复习记录表
    cur.execute("""
        CREATE TABLE IF NOT EXISTS review_logs (
            id TEXT PRIMARY KEY,
            card_id TEXT NOT NULL,
            quality INTEGER NOT NULL,       -- 0-5 评分
            reviewed_at TEXT NOT NULL,
            next_interval INTEGER,
            FOREIGN KEY (card_id) REFERENCES knowledge_cards(id) ON DELETE CASCADE
        )
    """)

    # 全文搜索索引（SQLite FTS5）
    cur.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS knowledge_fts USING fts5(
            title, content, tags,
            content='knowledge_cards',
            content_rowid='rowid'
        )
    """)

    # 触发器：保持 FTS 索引同步
    cur.execute("""
        CREATE TRIGGER IF NOT EXISTS knowledge_ai AFTER INSERT ON knowledge_cards BEGIN
            INSERT INTO knowledge_fts(rowid, title, content, tags)
            VALUES (NEW.rowid, NEW.title, NEW.content, NEW.tags);
        END
    """)

    cur.execute("""
        CREATE TRIGGER IF NOT EXISTS knowledge_ad AFTER DELETE ON knowledge_cards BEGIN
            INSERT INTO knowledge_fts(knowledge_fts, rowid, title, content, tags)
            VALUES ('delete', OLD.rowid, OLD.title, OLD.content, OLD.tags);
        END
    """)

    cur.execute("""
        CREATE TRIGGER IF NOT EXISTS knowledge_au AFTER UPDATE ON knowledge_cards BEGIN
            INSERT INTO knowledge_fts(rowid, title, content, tags)
            VALUES (NEW.rowid, NEW.title, NEW.content, NEW.tags);
        END
    """)

    conn.commit()
    conn.close()
    print(f"[LearnMind] 数据库初始化完成: {DB_PATH}")
