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
        .map((r) => listingFromRow((r as Map).cast<String, dynamic>()))
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
        'price_cents': listing.priceCents,
        'type': listing.type.name,
        'rating': listing.rating,
        'review_count': listing.reviewCount,
        'linked_post_id': listing.linkedPostId,
        'content_category': listing.contentCategory?.name,
        'genre': listing.genre?.name,
        'description': listing.description,
        'isbn': listing.isbn,
        'publisher': listing.publisher,
        'publication_date': listing.publicationDate?.toIso8601String(),
        'condition': listing.condition?.name,
        // Reuses the pre-existing (legacy, previously-unwritten) qty column
        // rather than adding a duplicate — see docs/database.md.
        'qty': listing.quantity,
        'edition': listing.edition,
        'shipping_methods': listing.shippingMethods.map((m) => m.name).toList(),
        'pickup_location': listing.pickupLocation,
        'pickup_phone': listing.pickupPhone,
        'meetup_location': listing.meetupLocation,
        'meetup_phone': listing.meetupPhone,
        'offer': listing.offer.name,
        'swap_wanted_for': listing.swapWantedFor,
        // Reuses the pre-existing (legacy, previously-unwritten) is_sold_out
        // column rather than adding a duplicate — see docs/database.md.
        'is_sold_out': listing.isSoldOut,
        'pdf_file_name': listing.pdfFileName,
        'ebook_content': listing.ebookContent,
        'cover_image_url': listing.coverImageUrl,
        'cover_color': listing.coverColor,
      };

  /// Maps a raw `marketplace_listings` row (with its embedded
  /// `ebook_chapters`/`audio_volumes`) to a [MarketplaceListing]. Public so
  /// [CommerceRepository] can reuse it when embedding listings under
  /// `order_items` rows.
  static MarketplaceListing listingFromRow(Map<String, dynamic> row) {
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
      priceCents: (row['price_cents'] as num?)?.toInt() ?? 0,
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
      isbn: row['isbn'] as String?,
      publisher: row['publisher'] as String?,
      publicationDate: row['publication_date'] == null
          ? null
          : DateTime.tryParse(row['publication_date'] as String),
      condition: row['condition'] == null
          ? null
          : ListingCondition.values.firstWhere(
              (c) => c.name == row['condition'],
              orElse: () => ListingCondition.good,
            ),
      quantity: (row['qty'] as num?)?.toInt(),
      edition: row['edition'] as String?,
      shippingMethods: [
        for (final name
            in ((row['shipping_methods'] as List?) ?? const [])
                .whereType<String>())
          if (ShippingMethod.values.any((m) => m.name == name))
            ShippingMethod.values.firstWhere((m) => m.name == name),
      ],
      pickupLocation: row['pickup_location'] as String?,
      pickupPhone: row['pickup_phone'] as String?,
      meetupLocation: row['meetup_location'] as String?,
      meetupPhone: row['meetup_phone'] as String?,
      offer: row['offer'] == null
          ? ListingOffer.sale
          : ListingOffer.values.firstWhere(
              (o) => o.name == row['offer'],
              orElse: () => ListingOffer.sale,
            ),
      swapWantedFor: row['swap_wanted_for'] as String?,
      isSoldOut: (row['is_sold_out'] as bool?) ?? false,
      pdfFileName: row['pdf_file_name'] as String?,
      ebookContent: row['ebook_content'] as String?,
      coverImageUrl: row['cover_image_url'] as String?,
      coverColor: (row['cover_color'] as num?)?.toInt(),
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
