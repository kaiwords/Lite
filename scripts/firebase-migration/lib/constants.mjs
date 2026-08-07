// Mirrors mobile-app/lib/models/post.dart's ContentCategory enum exactly —
// keep in sync if that enum ever changes.
export const VALID_CATEGORIES = [
  'poem', 'book', 'joke', 'novel', 'article', 'story',
  'essay', 'haiku', 'biography', 'shortStory', 'script', 'lyrics',
];
export const DEFAULT_CATEGORY = 'book';

export function classifyListingType(bookType) {
  const s = (bookType ?? '').toLowerCase();
  if (s.includes('audio')) return 'audio';
  if (s.includes('ebook') || s.includes('e-book')) return 'ebook';
  if (s.includes('physical')) return 'physical';
  return null;
}
export const DEFAULT_LISTING_TYPE = 'physical';
