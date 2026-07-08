# Database

## Current state: no real database.

The app has **zero** network calls and **zero** server-side storage. What
stands in for a database today is entirely on-device:

| Layer | What it is | Where |
|---|---|---|
| Seed data | Hard-coded Dart lists (`mockUsers`, `mockPosts`, `mockListings`, `mockComments`, `mockBooks`) acting as fixed "row" data | `lib/models/*.dart` |
| Local persistence | `shared_preferences` — an Android/iOS key-value store, wrapped by the `LocalStore` singleton. Lists are JSON-encoded strings under fixed keys (`posts`, `cart`, `purchases`, `my_listings`, `comments`, `current_user`, `theme_mode`, `follows`, `visible_categories`) | `lib/services/local_store.dart` |

This is **not** a database in any real sense: no querying, no relations
enforced, no multi-user isolation, no transactions, no migrations. It's
per-device, per-install storage that happens to model the shape a database
would eventually have.

## Entities (current shape, as Dart models)

- **User** (`LitUser`) — id, username, displayName, avatarUrl, bio,
  followersCount, followingCount, postsCount, earnings, isFollowing,
  isVerified
- **Post** — id, author (embedded User), title, content, category (enum),
  createdAt, likesCount, commentsCount, sharesCount, isLiked, isFavourited,
  audioUrl, coverImageUrl, linkedListingId, bookId
- **Comment** — id, postId, author (embedded User), text, createdAt,
  likesCount, isLiked
- **MarketplaceListing** — id, title, authorName, price (string, not a
  numeric/currency type), type (physical/ebook/audio), rating, reviewCount,
  linkedPostId, contentCategory, genre, description, pdfFileName,
  ebookContent, audioVolumes
- **Purchase** — referenced by `LocalStore` (`loadPurchases`/`savePurchases`)
- **Book** — id, title, authorName, subtitle, coverColor, coverTextColor,
  pages (each with type/chapterTitle/content)

Note: several relations are denormalized (e.g. `Post.author` embeds a full
`LitUser` rather than a foreign key; `MarketplaceListing.authorName` is a
plain string rather than a reference to a `LitUser`). A real schema would
need to normalize these.

## When a real database is introduced

Needs to be decided alongside [`../web-app`](../web-app) /
[`../mobile-app`](../mobile-app), since both clients would share one
backend and one database. Candidates to evaluate at that point:

- Relational (Postgres) — natural fit given the clearly relational entities
  above (users, posts, comments, listings, purchases) and need for
  transactional integrity around purchases/payments
- Managed backend-as-a-service (e.g. Firebase/Supabase) — faster to stand up
  if auth + file storage + database are wanted together

**Nothing has been decided yet** — this section exists to frame the choice,
not to record one.
