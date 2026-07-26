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

  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.authorName,
    required this.price,
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
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authorName': authorName,
        'price': price,
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
      };

  factory MarketplaceListing.fromJson(Map<String, dynamic> j) =>
      MarketplaceListing(
        id: j['id'] as String,
        title: j['title'] as String,
        authorName: j['authorName'] as String,
        price: j['price'] as String,
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

final mockListings = const [
  // ── Physical Books ─────────────────────────────────────────────────────────
  MarketplaceListing(
    id: 'm1',
    title: 'The Glass House',
    authorName: 'Eleanor Voss',
    price: '\$14.99',
    type: ListingType.physical,
    rating: 4.7,
    reviewCount: 312,
    linkedPostId: 'p5',
    contentCategory: ContentCategory.novel,
    genre: Genre.literaryFiction,
    description:
        'A haunting novel about memory, identity, and the fragile walls we build between ourselves and the truth. Eleanor Voss weaves a story of a woman who returns to her childhood home only to find that the life she remembered was never quite real. Lyrical, devastating, and impossible to put down.',
  ),
  MarketplaceListing(
    id: 'm2',
    title: 'Salt & Smoke',
    authorName: 'Marcus Osei',
    price: '\$12.99',
    type: ListingType.physical,
    rating: 4.4,
    reviewCount: 188,
    contentCategory: ContentCategory.novel,
    genre: Genre.historical,
    description:
        'Set against the backdrop of a coastal fishing village, Salt & Smoke follows three generations of a family bound by secrets, stubbornness, and the sea. Marcus Osei\'s debut novel is a slow-burning, richly atmospheric portrait of love and loss that lingers long after the final page.',
  ),
  MarketplaceListing(
    id: 'm3',
    title: 'Midnight Verses',
    authorName: 'Eleanor Voss',
    price: '\$11.99',
    type: ListingType.physical,
    rating: 4.6,
    reviewCount: 245,
    contentCategory: ContentCategory.poem,
    genre: Genre.poetry,
    description:
        'A stunning debut poetry collection exploring insomnia, longing, and the quiet hours when the world goes still. Midnight Verses is Eleanor Voss at her most intimate — each poem a small, precise wound. Winner of the Northlight Poetry Prize.',
  ),
  MarketplaceListing(
    id: 'm4',
    title: 'Borrowed Time',
    authorName: 'Javier Morales',
    price: '\$9.99',
    type: ListingType.physical,
    rating: 4.2,
    reviewCount: 97,
    contentCategory: ContentCategory.story,
    genre: Genre.romance,
    description:
        'Twelve interconnected short stories about ordinary people caught between who they are and who they wish they had become. Written in both English and Spanish, Borrowed Time moves fluidly across borders of language, culture, and the heart.',
  ),
  MarketplaceListing(
    id: 'm13',
    title: 'The Iron Kingdom',
    authorName: 'Reza Karimi',
    price: '\$16.99',
    type: ListingType.physical,
    rating: 4.8,
    reviewCount: 503,
    contentCategory: ContentCategory.novel,
    genre: Genre.fantasy,
    description:
        'A sprawling epic fantasy set in a world where magic is outlawed and stories are the only rebellion left. Reza Karimi\'s debut fantasy novel is richly imagined, politically sharp, and impossible to put down.',
  ),
  MarketplaceListing(
    id: 'm14',
    title: 'The Last Signal',
    authorName: 'Marcus Osei',
    price: '\$13.99',
    type: ListingType.physical,
    rating: 4.5,
    reviewCount: 274,
    contentCategory: ContentCategory.novel,
    genre: Genre.sciFi,
    description:
        'In a near-future world where human memory can be uploaded and sold, one archivist discovers a signal no one was supposed to find. A propulsive, deeply human science fiction thriller.',
  ),
  MarketplaceListing(
    id: 'm15',
    title: 'Before the Storm Breaks',
    authorName: 'Priya Nair',
    price: '\$12.49',
    type: ListingType.physical,
    rating: 4.3,
    reviewCount: 189,
    contentCategory: ContentCategory.novel,
    genre: Genre.thriller,
    description:
        'A literary thriller set across three continents. Two strangers receive the same anonymous letter. What follows is a race against time, identity, and the truth they both tried to bury.',
  ),

  // ── E-Books ────────────────────────────────────────────────────────────────
  MarketplaceListing(
    id: 'm5',
    title: 'Solitudes',
    authorName: 'Priya Nair',
    price: '\$6.99',
    type: ListingType.ebook,
    rating: 4.5,
    reviewCount: 421,
    contentCategory: ContentCategory.poem,
    genre: Genre.poetry,
    description:
        'Priya Nair\'s Solitudes is a meditation on aloneness — not loneliness, but the chosen quiet that allows a writer to hear herself think. These poems move from Mumbai to Montreal, tracing a diaspora of feeling. One of the most celebrated poetry e-books of the year.',
  ),
  MarketplaceListing(
    id: 'm6',
    title: 'Whisper Theory',
    authorName: 'Priya Nair',
    price: '\$5.99',
    type: ListingType.ebook,
    rating: 4.3,
    reviewCount: 163,
    contentCategory: ContentCategory.essay,
    genre: Genre.selfHelp,
    description:
        'A collection of personal essays on reading, writing, and the strange intimacy of words on a page. Whisper Theory asks: what does a book do to you when no one is watching? Sharp, funny, and unexpectedly moving — Priya Nair at her essayistic best.',
  ),
  MarketplaceListing(
    id: 'm7',
    title: 'The Long Road',
    authorName: 'Javier Morales',
    price: '\$7.99',
    type: ListingType.ebook,
    rating: 4.1,
    reviewCount: 209,
    contentCategory: ContentCategory.novel,
    genre: Genre.literaryFiction,
    description:
        'A road novel told in fragments: a father and son drive across a country neither fully belongs to, speaking in half-sentences about things they can\'t quite name. The Long Road is sparse, honest, and quietly devastating.',
  ),
  MarketplaceListing(
    id: 'm8',
    title: 'Letters Never Sent',
    authorName: 'Priya Nair',
    price: '\$4.99',
    type: ListingType.ebook,
    rating: 4.8,
    reviewCount: 534,
    contentCategory: ContentCategory.story,
    genre: Genre.romance,
    description:
        'What if you wrote every letter you were afraid to send? Letters Never Sent is a fictional epistolary collection — love letters, apologies, confessions, and farewells — addressed to people real and imagined. Priya Nair\'s most beloved work.',
  ),
  MarketplaceListing(
    id: 'm16',
    title: 'The Haunting of Veld House',
    authorName: 'Eleanor Voss',
    price: '\$5.49',
    type: ListingType.ebook,
    rating: 4.6,
    reviewCount: 318,
    contentCategory: ContentCategory.story,
    genre: Genre.horror,
    description:
        'Eight interconnected ghost stories set in the same crumbling estate across different centuries. Eleanor Voss\'s horror collection is atmospheric, precise, and deeply unsettling.',
  ),
  MarketplaceListing(
    id: 'm17',
    title: 'Stars We Cannot Name',
    authorName: 'Reza Karimi',
    price: '\$6.49',
    type: ListingType.ebook,
    rating: 4.7,
    reviewCount: 441,
    contentCategory: ContentCategory.novel,
    genre: Genre.sciFi,
    description:
        'A quiet, emotional science fiction novel about first contact — not with aliens, but with the version of ourselves we\'ve been avoiding. Reza Karimi\'s most celebrated work.',
  ),
  MarketplaceListing(
    id: 'm18',
    title: 'Laughter at the Edge',
    authorName: 'Marcus Osei',
    price: '\$3.99',
    type: ListingType.ebook,
    rating: 4.4,
    reviewCount: 227,
    contentCategory: ContentCategory.joke,
    genre: Genre.humor,
    description:
        'A collection of comic essays, absurdist fiction, and sharp observations about modern life. Marcus Osei is at his funniest and most incisive.',
  ),

  // ── Audio Books ────────────────────────────────────────────────────────────
  MarketplaceListing(
    id: 'm9',
    title: 'Between the Lines',
    authorName: 'Eleanor Voss',
    price: '\$8.99',
    type: ListingType.audio,
    rating: 4.9,
    reviewCount: 678,
    linkedPostId: 'p1',
    contentCategory: ContentCategory.poem,
    genre: Genre.poetry,
    description:
        'Eleanor Voss reads her award-winning poem collection in this intimate audio edition. Recorded in a single session with only ambient sound, Between the Lines is an experience unlike any other — poetry as it was always meant to be heard. Running time: 1h 12m.',
  ),
  MarketplaceListing(
    id: 'm10',
    title: 'Why We Read Alone',
    authorName: 'Reza Karimi',
    price: '\$9.99',
    type: ListingType.audio,
    rating: 4.6,
    reviewCount: 302,
    linkedPostId: 'p2',
    contentCategory: ContentCategory.article,
    genre: Genre.selfHelp,
    description:
        'A thoughtful audio essay exploring the psychology of solitary reading — why we retreat into books, what we\'re looking for, and what we find. Reza Karimi\'s warm, unhurried narration makes this essential listening for any book lover. Running time: 48m.',
  ),
  MarketplaceListing(
    id: 'm11',
    title: 'Dark Fictions Vol. 1',
    authorName: 'Marcus Osei',
    price: '\$7.99',
    type: ListingType.audio,
    rating: 4.4,
    reviewCount: 155,
    contentCategory: ContentCategory.story,
    genre: Genre.horror,
    description:
        'Six original dark fiction short stories performed by the author with full atmospheric sound design. From coastal ghost stories to urban psychological thrillers — Marcus Osei\'s voice brings each unsettling tale to vivid, uncomfortable life. Running time: 2h 05m.',
  ),
  MarketplaceListing(
    id: 'm12',
    title: 'Morning Without You',
    authorName: 'Javier Morales',
    price: '\$5.99',
    type: ListingType.audio,
    rating: 4.8,
    reviewCount: 241,
    linkedPostId: 'p4',
    contentCategory: ContentCategory.haiku,
    genre: Genre.poetry,
    description:
        'A haiku cycle performed in both Spanish and English, set to gentle acoustic guitar. Javier Morales wrote these 40 haiku over the course of a single winter after loss. Morning Without You is tender, spare, and deeply restorative. Running time: 22m.',
  ),
  MarketplaceListing(
    id: 'm19',
    title: 'Echoes of the Iron Kingdom',
    authorName: 'Reza Karimi',
    price: '\$10.99',
    type: ListingType.audio,
    rating: 4.7,
    reviewCount: 389,
    contentCategory: ContentCategory.novel,
    genre: Genre.fantasy,
    description:
        'The full audio dramatization of The Iron Kingdom, performed by a cast of twelve with original score. An immersive fantasy listening experience. Running time: 14h 30m.',
  ),
  MarketplaceListing(
    id: 'm20',
    title: 'The Code of Forgotten Stars',
    authorName: 'Eleanor Voss',
    price: '\$8.49',
    type: ListingType.audio,
    rating: 4.5,
    reviewCount: 196,
    contentCategory: ContentCategory.novel,
    genre: Genre.mystery,
    description:
        'A slow-burn audio mystery read by the author herself. A cryptographer receives a manuscript written in a code only she can break — but solving it may cost her everything. Running time: 6h 48m.',
  ),
  MarketplaceListing(
    id: 'mBook1',
    title: 'The Ember Throne',
    authorName: 'Adriana Voss',
    price: '\$9.99',
    type: ListingType.ebook,
    rating: 4.9,
    reviewCount: 812,
    contentCategory: ContentCategory.novel,
    genre: Genre.fantasy,
    description:
        'A luminous debut fantasy. When the ancient Ember Throne summons a girl from the provinces, she must navigate the treacherous court of Kaleth — where magic is power and stories are the only rebellion left.',
  ),
];
