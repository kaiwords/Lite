import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace.dart';
import '../models/post.dart';
import 'supabase_service.dart';

/// Reads and writes [MarketplaceListing] rows (with their chapters/volumes)
/// in Supabase.
class MarketplaceRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<MarketplaceListing>> fetchAll() async {
    final rows = await _client
        .from('marketplace_listings')
        .select('*, ebook_chapters(*), audio_volumes(*)');
    return (rows as List)
        .map((r) => _listingFromRow((r as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<void> insert(MarketplaceListing listing) async {
    await _client.from('marketplace_listings').insert(_listingRow(listing));
    await _insertChildRows(listing);
  }

  static Future<void> update(MarketplaceListing listing) async {
    await _client
        .from('marketplace_listings')
        .update(_listingRow(listing))
        .eq('id', listing.id);
    // Simplest correct way to reconcile chapters/volumes on edit: replace them.
    await _client.from('ebook_chapters').delete().eq('listing_id', listing.id);
    await _client.from('audio_volumes').delete().eq('listing_id', listing.id);
    await _insertChildRows(listing);
  }

  static Future<void> _insertChildRows(MarketplaceListing listing) async {
    if (listing.ebookChapters.isNotEmpty) {
      await _client.from('ebook_chapters').insert([
        for (var i = 0; i < listing.ebookChapters.length; i++)
          {
            'listing_id': listing.id,
            'position': i,
            'title': listing.ebookChapters[i].title,
            'content': listing.ebookChapters[i].content,
          },
      ]);
    }
    if (listing.audioVolumes.isNotEmpty) {
      await _client.from('audio_volumes').insert([
        for (var i = 0; i < listing.audioVolumes.length; i++)
          {
            'listing_id': listing.id,
            'position': i,
            'title': listing.audioVolumes[i].title,
            'file_name': listing.audioVolumes[i].fileName,
          },
      ]);
    }
  }

  static Map<String, dynamic> _listingRow(MarketplaceListing listing) => {
        'id': listing.id,
        'title': listing.title,
        'author_name': listing.authorName,
        'price': listing.price,
        'type': listing.type.name,
        'rating': listing.rating,
        'review_count': listing.reviewCount,
        'linked_post_id': listing.linkedPostId,
        'content_category': listing.contentCategory?.name,
        'genre': listing.genre?.name,
        'description': listing.description,
        'pdf_file_name': listing.pdfFileName,
        'ebook_content': listing.ebookContent,
      };

  static MarketplaceListing _listingFromRow(Map<String, dynamic> row) {
    final chapterRows = ((row['ebook_chapters'] as List?) ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList()
      ..sort((a, b) => (a['position'] as num).compareTo(b['position'] as num));
    final volumeRows = ((row['audio_volumes'] as List?) ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList()
      ..sort((a, b) => (a['position'] as num).compareTo(b['position'] as num));

    return MarketplaceListing(
      id: row['id'] as String,
      title: row['title'] as String,
      authorName: row['author_name'] as String,
      price: row['price'] as String,
      type: ListingType.values.firstWhere(
        (t) => t.name == row['type'],
        orElse: () => ListingType.physical,
      ),
      rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
      linkedPostId: row['linked_post_id'] as String?,
      contentCategory: row['content_category'] == null
          ? null
          : contentCategoryFromName(row['content_category'] as String?),
      genre: row['genre'] == null
          ? null
          : Genre.values.firstWhere(
              (g) => g.name == row['genre'],
              orElse: () => Genre.literaryFiction,
            ),
      description: (row['description'] as String?) ?? '',
      pdfFileName: row['pdf_file_name'] as String?,
      ebookContent: row['ebook_content'] as String?,
      ebookChapters: chapterRows
          .map((c) => EbookChapter(
                title: c['title'] as String,
                content: c['content'] as String,
              ))
          .toList(),
      audioVolumes: volumeRows
          .map((v) => AudioVolume(
                title: v['title'] as String,
                fileName: v['file_name'] as String,
              ))
          .toList(),
    );
  }
}
