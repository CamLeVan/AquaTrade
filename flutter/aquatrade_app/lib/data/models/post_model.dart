class PostModel {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String? status;
  final String? featuredImageUrl;
  final String? author;
  final int? viewCount;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.status,
    this.featuredImageUrl,
    this.author,
    this.viewCount,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString(),
      status: json['status']?.toString(),
      featuredImageUrl: json['featuredImageUrl']?.toString(),
      author: json['author']?.toString(),
      viewCount: json['viewCount'] is num ? (json['viewCount'] as num).toInt() : null,
    );
  }
}
