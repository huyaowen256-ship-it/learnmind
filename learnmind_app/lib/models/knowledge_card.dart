/// 知识卡片数据模型
class KnowledgeCard {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String createdAt;
  final String updatedAt;
  final SM2Data sm2Data;

  KnowledgeCard({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.sm2Data,
  });

  factory KnowledgeCard.fromJson(Map<String, dynamic> json) {
    return KnowledgeCard(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      sm2Data: SM2Data.fromJson(json['sm2_data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sm2_data': sm2Data.toJson(),
      };

  /// 格式化创建时间
  String get createdAtFormatted {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 是否需要复习
  bool get needsReview {
    if (sm2Data.nextReview == null) return true;
    final next = DateTime.tryParse(sm2Data.nextReview!);
    if (next == null) return true;
    return DateTime.now().isAfter(next);
  }

  /// 复习状态标签
  String get reviewStatusLabel {
    if (sm2Data.lastReview == null) return '新卡片';
    if (needsReview) return '待复习';
    return '已掌握';
  }
}

/// SM-2 间隔重复数据
class SM2Data {
  final double easinessFactor;
  final int interval;
  final int repetitions;
  final String? nextReview;
  final String? lastReview;

  SM2Data({
    this.easinessFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReview,
    this.lastReview,
  });

  factory SM2Data.fromJson(Map<String, dynamic> json) => SM2Data(
        easinessFactor: (json['easiness_factor'] ?? 2.5).toDouble(),
        interval: json['interval'] ?? 0,
        repetitions: json['repetitions'] ?? 0,
        nextReview: json['next_review'],
        lastReview: json['last_review'],
      );

  Map<String, dynamic> toJson() => {
        'easiness_factor': easinessFactor,
        'interval': interval,
        'repetitions': repetitions,
        'next_review': nextReview,
        'last_review': lastReview,
      };

  /// 下次复习时间（人类可读）
  String get nextReviewLabel {
    if (nextReview == null) return '立即复习';
    final next = DateTime.tryParse(nextReview!);
    if (next == null) return nextReview!;

    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return '已到期';
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '明天';
    return '${diff.inDays}天后';
  }
}

/// 复习题
class ReviewQuestion {
  final String cardId;
  final String question;
  final String questionType; // 'multiple_choice' | 'short_answer'
  final List<String>? options;
  final String answer;

  ReviewQuestion({
    required this.cardId,
    required this.question,
    required this.questionType,
    this.options,
    required this.answer,
  });

  factory ReviewQuestion.fromJson(Map<String, dynamic> json) => ReviewQuestion(
        cardId: json['card_id'] ?? '',
        question: json['question'] ?? '',
        questionType: json['question_type'] ?? 'short_answer',
        options: json['options'] != null ? List<String>.from(json['options']) : null,
        answer: json['answer'] ?? '',
      );
}

/// 复习题目集
class ReviewQuestionSet {
  final String cardId;
  final String cardTitle;
  final List<ReviewQuestion> questions;
  final String sessionId;

  ReviewQuestionSet({
    required this.cardId,
    required this.cardTitle,
    required this.questions,
    required this.sessionId,
  });

  factory ReviewQuestionSet.fromJson(Map<String, dynamic> json) => ReviewQuestionSet(
        cardId: json['card_id'] ?? '',
        cardTitle: json['card_title'] ?? '',
        questions: (json['questions'] as List? ?? [])
            .map((q) => ReviewQuestion.fromJson(q))
            .toList(),
        sessionId: json['session_id'] ?? '',
      );
}

/// 复习结果
class ReviewResult {
  final String cardId;
  final bool correct;
  final String feedback;
  final String nextReview;
  final int newInterval;
  final double newEasinessFactor;

  ReviewResult({
    required this.cardId,
    required this.correct,
    required this.feedback,
    required this.nextReview,
    required this.newInterval,
    required this.newEasinessFactor,
  });

  factory ReviewResult.fromJson(Map<String, dynamic> json) => ReviewResult(
        cardId: json['card_id'] ?? '',
        correct: json['correct'] ?? false,
        feedback: json['feedback'] ?? '',
        nextReview: json['next_review'] ?? '',
        newInterval: json['new_interval'] ?? 0,
        newEasinessFactor: (json['new_easiness_factor'] ?? 2.5).toDouble(),
      );
}

/// 今日复习仪表盘
class ReviewDashboard {
  final int count;
  final List<KnowledgeCard> cards;

  ReviewDashboard({required this.count, required this.cards});

  factory ReviewDashboard.fromJson(Map<String, dynamic> json) => ReviewDashboard(
        count: json['count'] ?? 0,
        cards: (json['cards'] as List? ?? [])
            .map((c) => KnowledgeCard.fromJson(c))
            .toList(),
      );
}
