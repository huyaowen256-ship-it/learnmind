"""
SM-2 间隔重复算法实现
SuperMemo SM-2 — 经过验证的记忆强化算法
"""
from datetime import datetime, timedelta
from typing import Tuple


def calculate_sm2(
    quality: int,
    easiness_factor: float,
    interval: int,
    repetitions: int,
) -> Tuple[float, int, int]:
    """
    SM-2 算法核心计算

    参数:
        quality: 评分 0-5
            0 - 完全忘记
            1 - 错误，但看到答案后想起来
            2 - 错误，但觉得快想起来了
            3 - 正确，但有些犹豫
            4 - 正确，有点犹豫
            5 - 完美记住
        easiness_factor: 难度系数（初始2.5）
        interval: 当前间隔天数
        repetitions: 连续正确次数

    返回:
        (新easiness_factor, 新interval, 新repetitions)
    """
    # 修正评分：如果 quality < 3，重置 repetitions
    if quality < 3:
        # 失败：从头开始
        new_repetitions = 0
        new_interval = 1
    else:
        # 成功
        new_repetitions = repetitions + 1
        if new_repetitions == 1:
            new_interval = 1
        elif new_repetitions == 2:
            new_interval = 6
        else:
            new_interval = round(interval * easiness_factor)

    # 更新 easiness_factor
    # EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    new_ef = easiness_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))

    # EF 最低为 1.3
    if new_ef < 1.3:
        new_ef = 1.3

    return round(new_ef, 2), new_interval, new_repetitions


def get_next_review_date(interval_days: int) -> str:
    """计算下次复习日期"""
    next_date = datetime.now() + timedelta(days=interval_days)
    return next_date.isoformat()


def quality_from_review_result(correct: bool, confidence: str) -> int:
    """
    辅助函数：根据答题结果推断 SM-2 quality

    correct: 是否答对
    confidence: "low" | "medium" | "high"
    """
    if not correct:
        if confidence == "high":
            return 1  # 差一点就想起来
        return 0  # 完全忘记

    # 答对了
    if confidence == "high":
        return 5  # 完美
    elif confidence == "medium":
        return 4  # 有点犹豫但正确
    else:
        return 3  # 正确但不确定


# 质量评分中文映射（用于生成选项）
QUALITY_DESCRIPTIONS = {
    0: "完全忘记，答案都想不起来了",
    1: "错误，但看到答案后想起来了",
    2: "错误，感觉快要想起来了",
    3: "正确，但有些犹豫",
    4: "正确，没有犹豫",
    5: "完美记住，脱口而出",
}
