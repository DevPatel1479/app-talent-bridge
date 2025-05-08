class JobPost {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final double salary;
  final String category;
  final List<String> requiredSkills;
  final List<Milestone> milestones;
  final String jobType;
  final DateTime datePosted;
  final DateTime validUntil;
  final String state;
  final String city;

  JobPost({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.salary,
    required this.category,
    required this.requiredSkills,
    required this.milestones,
    required this.jobType,
    required this.datePosted,
    required this.validUntil,
    required this.state,
    required this.city,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    // parse skills
    List<String> parsedSkills = [];
    if (json['required_skills'] is List) {
      parsedSkills =
          (json['required_skills'] as List).map((e) => e.toString()).toList();
    }

    // parse milestones
    List<Milestone> milestonesList = [];
    if (json['milestones'] != null && json['milestones'] is List) {
      milestonesList = (json['milestones'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => Milestone.fromJson(e))
          .toList();
    }

    // parse posted date
    DateTime parsePosted(dynamic date) {
      if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      } else if (date is Map<String, dynamic> && date.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (date['_seconds'] as int) * 1000,
        );
      }
      return DateTime.now();
    }

    return JobPost(
      id: json['job_id'] ?? '',
      clientId: json['client_id'] ?? '',
      title: json['job_title'] ?? '',
      description: json['description'] ?? '',
      salary: (json['budget'] is num)
          ? (json['budget'] as num).toDouble()
          : double.tryParse(json['budget']?.toString() ?? '0') ?? 0,
      category: json['job_category'] ?? '',
      requiredSkills: parsedSkills,
      milestones: (json['milestones'] is List)
          ? (json['milestones'] as List)
              .whereType<Map<String, dynamic>>()
              .map((milestone) => Milestone.fromJson(milestone))
              .toList()
          : [],
      jobType: json['payment_type'] ?? '',
      state: json['state'] ?? '',
      city: json['district'] ?? '',
      datePosted: parsePosted(json['posted_date']),
      validUntil: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toJson() => {
        'job_id': id,
        'client_id': clientId,
        'job_title': title,
        'description': description,
        'budget': salary,
        'job_category': category,
        'required_skills': requiredSkills,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'payment_type': jobType,
        'state': state,
        'district': city,
        'posted_date': datePosted.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
      };
}

// Milestone class to handle the milestone objects
class Milestone {
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  Milestone({
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic date) {
      if (date is String) {
        return DateTime.parse(date);
      } else if (date is Map<String, dynamic>) {
        if (date.containsKey('_seconds')) {
          return DateTime.fromMillisecondsSinceEpoch(date['_seconds'] * 1000);
        }
      }
      throw FormatException("Invalid date format");
    }

    return Milestone(
      title: json['title'],
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}
