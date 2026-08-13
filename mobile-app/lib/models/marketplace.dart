import 'package:flutter/material.dart';
import 'post.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Genre — what the book is *about*
// ─────────────────────────────────────────────────────────────────────────────

enum Genre {
  fantasy,
  romance,
  sciFi,
  mystery,
  horror,
  historical,
  literaryFiction,
  poetry,
  selfHelp,
  biography,
  thriller,
  humor,
}

extension GenreExt on Genre {
  String get label => switch (this) {
    Genre.fantasy        => 'Fantasy',
    Genre.romance        => 'Romance',
    Genre.sciFi          => 'Sci-Fi',
    Genre.mystery        => 'Mystery',
    Genre.horror         => 'Horror',
    Genre.historical     => 'Historical',
    Genre.literaryFiction => 'Literary Fiction',
    Genre.poetry         => 'Poetry',
    Genre.selfHelp       => 'Self-Help',
    Genre.biography      => 'Biography',
    Genre.thriller       => 'Thriller',
    Genre.humor          => 'Humor',
  };

  String get emoji => switch (this) {
    Genre.fantasy        => '🧙',
    Genre.romance        => '💕',
    Genre.sciFi          => '🚀',
    Genre.mystery        => '🔍',
    Genre.horror         => '👻',
    Genre.historical     => '🏛️',
    Genre.literaryFiction => '📖',
    Genre.poetry         => '🖊️',
    Genre.selfHelp       => '✨',
    Genre.biography      => '👤',
    Genre.thriller       => '⚡',
    Genre.humor          => '😄',
  };

  // Tile gradient colors [top, bottom]
  List<Color> get colors => switch (this) {
    Genre.fantasy        => [const Color(0xFF6B4EAA), const Color(0xFF3D2B6B)],
    Genre.romance        => [const Color(0xFFD4607A), const Color(0xFF8B2E45)],
    Genre.sciFi          => [const Color(0xFF2E6BA5), const Color(0xFF0D3559)],
    Genre.mystery        => [const Color(0xFF3D3D6B), const Color(0xFF1A1A35)],
    Genre.horror         => [const Color(0xFF5C1A1A), const Color(0xFF2D0D0D)],
    Genre.historical     => [const Color(0xFF7A5C2E), const Color(0xFF4A3518)],
    Genre.literaryFiction => [const Color(0xFF2E6B5C), const Color(0xFF0D3530)],
    Genre.poetry         => [const Color(0xFF8B6BAA), const Color(0xFF4A3568)],
    Genre.selfHelp       => [const Color(0xFF5C8B3D), const Color(0xFF2D4A1A)],
    Genre.biography      => [const Color(0xFF5C6B7A), const Color(0xFF2D3D4A)],
    Genre.thriller       => [const Color(0xFF8B5C1A), const Color(0xFF4A2D0D)],
    Genre.humor          => [const Color(0xFFD4A017), const Color(0xFF8B6800)],
  };
}

// ─────────────────────────────────────────────────────────────────────────────

enum ListingType { physical, ebook, audio }

extension ListingTypeExt on ListingType {
  String get label => switch (this) {
        ListingType.physical => 'Physical',
        ListingType.ebook => 'E-Book',
        ListingType.audio => 'Audio',
      };

  String get ctaLabel => switch (this) {
        ListingType.physical => 'Buy Now',
        ListingType.ebook => 'Download',
        ListingType.audio => 'Listen',
      };

  IconData get icon => switch (this) {
        ListingType.physical => Icons.menu_book_rounded,
        ListingType.ebook => Icons.tablet_mac_rounded,
        ListingType.audio => Icons.headphones_rounded,
      };

  Color get badgeColor => switch (this) {
        ListingType.physical => const Color(0xFF5C7A5C),
        ListingType.ebook => const Color(0xFF4A6FA5),
        ListingType.audio => const Color(0xFF9B5C8A),
      };
}

/// A single chapter of a chapter-built e-book (see [MarketplaceListing.ebookChapters]).
class EbookChapter {
  final String title;
  final String content;

  const EbookChapter({required this.title, required this.content});

  Map<String, dynamic> toJson() => {'title': title, 'content': content};

  factory EbookChapter.fromJson(Map<String, dynamic> j) => EbookChapter(
        title: (j['title'] as String?) ?? '',
        content: (j['content'] as String?) ?? '',
      );
}

/// A single track/volume of an audiobook, with a seller-chosen [title]
/// (e.g. "Chapter 1" or "Track 2: The Storm") alongside the uploaded
/// [fileName]. See [MarketplaceListing.audioVolumes].
class AudioVolume {
  final String title;
  final String fileName;

  const AudioVolume({required this.title, required this.fileName});

  Map<String, dynamic> toJson() => {'title': title, 'fileName': fileName};

  factory AudioVolume.fromJson(Map<String, dynamic> j) => AudioVolume(
        title: (j['title'] as String?) ?? '',
        fileName: (j['fileName'] as String?) ?? '',
      );
}

class MarketplaceListing {
  final String id;
  final String title;
  final String authorName;
  final String price;
  // Canonical amount in cents — the source of truth for anything that
  // touches money (Stripe checkout, seller payout splits). [price] stays a
  // display string for existing UI code. See docs/database.md.
  final int priceCents;
  final ListingType type;
  final double rating;
  final int reviewCount;
  final String? linkedPostId;
  final ContentCategory? contentCategory;
  final Genre? genre;
  final String description;

  // E-book source (set when listing an E-Book): the author either uploads a
  // PDF or writes the book online. At most one of these is non-null.
  final String? pdfFileName;
  final String? ebookContent;

  // Chapter-built e-book (set when the author writes the book online as
  // named chapters instead of one flat blob). When non-empty, this takes
  // precedence over [ebookContent] for the reading experience; [ebookContent]
  // is retained only for legacy single-blob listings.
  final List<EbookChapter> ebookChapters;

  // Audio book source (set when listing an Audio book): one uploaded audio file
  // per volume, each with a seller-chosen title. A single-volume audiobook has
  // one entry; multi-volume has more.
  final List<AudioVolume> audioVolumes;

  // Cover art, chosen in the "List a Book" sheet's Cover step. At most one
  // of these does the actual rendering: [coverImageUrl] (a picked photo —
  // local file path today, same convention as User.avatarUrl/coverImageUrl)
  // wins when set; otherwise [coverColor] (an ARGB int) drives the designed
  // gradient cover with title/author/decorative lines. Both null falls back
  // to a genre-derived color, same as before this field existed.
  final String? coverImageUrl;
  final int? coverColor;

  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.authorName,
    required this.price,
    this.priceCents = 0,
    required this.type,
    required this.rating,
    required this.reviewCount,
    this.linkedPostId,
    this.contentCategory,
    this.genre,
    this.description = '',
    this.pdfFileName,
    this.ebookContent,
    this.ebookChapters = const [],
    this.audioVolumes = const [],
    this.coverImageUrl,
    this.coverColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authorName': authorName,
        'price': price,
        'priceCents': priceCents,
        'type': type.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'linkedPostId': linkedPostId,
        'contentCategory': contentCategory?.name,
        'genre': genre?.name,
        'description': description,
        'pdfFileName': pdfFileName,
        'ebookContent': ebookContent,
        'ebookChapters': ebookChapters.map((c) => c.toJson()).toList(),
        'audioVolumes': audioVolumes.map((v) => v.toJson()).toList(),
        'coverImageUrl': coverImageUrl,
        'coverColor': coverColor,
      };

  factory MarketplaceListing.fromJson(Map<String, dynamic> j) =>
      MarketplaceListing(
        id: j['id'] as String,
        title: j['title'] as String,
        authorName: j['authorName'] as String,
        price: j['price'] as String,
        priceCents: (j['priceCents'] as num?)?.toInt() ?? 0,
        type: ListingType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => ListingType.physical,
        ),
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        linkedPostId: j['linkedPostId'] as String?,
        contentCategory: j['contentCategory'] == null
            ? null
            : contentCategoryFromName(j['contentCategory'] as String?),
        genre: j['genre'] == null
            ? null
            : Genre.values.firstWhere(
                (g) => g.name == j['genre'],
                orElse: () => Genre.literaryFiction,
              ),
        description: (j['description'] as String?) ?? '',
        pdfFileName: j['pdfFileName'] as String?,
        ebookContent: j['ebookContent'] as String?,
        ebookChapters: (j['ebookChapters'] as List?)
                ?.map((e) => EbookChapter.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        // Backward-compatible: older locally-saved data serialized volumes as
        // a plain List<String> of filenames. Migrate those to AudioVolume
        // entries with a sensible default title ("Volume 1", "Volume 2", …).
        audioVolumes: _parseAudioVolumes(j['audioVolumes']),
        coverImageUrl: j['coverImageUrl'] as String?,
        coverColor: (j['coverColor'] as num?)?.toInt(),
      );

  static List<AudioVolume> _parseAudioVolumes(dynamic raw) {
    if (raw is! List) return const [];
    final result = <AudioVolume>[];
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is String) {
        result.add(AudioVolume(title: 'Volume ${i + 1}', fileName: e));
      } else if (e is Map) {
        result.add(AudioVolume.fromJson(e.cast<String, dynamic>()));
      }
    }
    return result;
  }
}
