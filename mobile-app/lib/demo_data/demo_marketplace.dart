// Demo/sample marketplace listings — used only as a first-launch local seed
// until the real Supabase data loads (see CatalogueNotifier.loadFromSupabase
// in providers/marketplace_provider.dart), by the still-mock-only
// Purchases/Sales/My Listings account activity (providers/
// marketplace_account_provider.dart), and by tests.
import '../models/marketplace.dart';
import '../models/post.dart';

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

  // AUDIO DISABLED (2026-09-30): the six audio listings below are commented
  // out — the marketplace is book/e-book only for now.
  //   // ── Audio Books ────────────────────────────────────────────────────────────
  //   MarketplaceListing(
  //     id: 'm9',
  //     title: 'Between the Lines',
  //     authorName: 'Eleanor Voss',
  //     price: '\$8.99',
  //     type: ListingType.audio,
  //     rating: 4.9,
  //     reviewCount: 678,
  //     linkedPostId: 'p1',
  //     contentCategory: ContentCategory.poem,
  //     genre: Genre.poetry,
  //     description:
  //         'Eleanor Voss reads her award-winning poem collection in this intimate audio edition. Recorded in a single session with only ambient sound, Between the Lines is an experience unlike any other — poetry as it was always meant to be heard. Running time: 1h 12m.',
  //   ),
  //   MarketplaceListing(
  //     id: 'm10',
  //     title: 'Why We Read Alone',
  //     authorName: 'Reza Karimi',
  //     price: '\$9.99',
  //     type: ListingType.audio,
  //     rating: 4.6,
  //     reviewCount: 302,
  //     linkedPostId: 'p2',
  //     contentCategory: ContentCategory.article,
  //     genre: Genre.selfHelp,
  //     description:
  //         'A thoughtful audio essay exploring the psychology of solitary reading — why we retreat into books, what we\'re looking for, and what we find. Reza Karimi\'s warm, unhurried narration makes this essential listening for any book lover. Running time: 48m.',
  //   ),
  //   MarketplaceListing(
  //     id: 'm11',
  //     title: 'Dark Fictions Vol. 1',
  //     authorName: 'Marcus Osei',
  //     price: '\$7.99',
  //     type: ListingType.audio,
  //     rating: 4.4,
  //     reviewCount: 155,
  //     contentCategory: ContentCategory.story,
  //     genre: Genre.horror,
  //     description:
  //         'Six original dark fiction short stories performed by the author with full atmospheric sound design. From coastal ghost stories to urban psychological thrillers — Marcus Osei\'s voice brings each unsettling tale to vivid, uncomfortable life. Running time: 2h 05m.',
  //   ),
  //   MarketplaceListing(
  //     id: 'm12',
  //     title: 'Morning Without You',
  //     authorName: 'Javier Morales',
  //     price: '\$5.99',
  //     type: ListingType.audio,
  //     rating: 4.8,
  //     reviewCount: 241,
  //     linkedPostId: 'p4',
  //     contentCategory: ContentCategory.haiku,
  //     genre: Genre.poetry,
  //     description:
  //         'A haiku cycle performed in both Spanish and English, set to gentle acoustic guitar. Javier Morales wrote these 40 haiku over the course of a single winter after loss. Morning Without You is tender, spare, and deeply restorative. Running time: 22m.',
  //   ),
  //   MarketplaceListing(
  //     id: 'm19',
  //     title: 'Echoes of the Iron Kingdom',
  //     authorName: 'Reza Karimi',
  //     price: '\$10.99',
  //     type: ListingType.audio,
  //     rating: 4.7,
  //     reviewCount: 389,
  //     contentCategory: ContentCategory.novel,
  //     genre: Genre.fantasy,
  //     description:
  //         'The full audio dramatization of The Iron Kingdom, performed by a cast of twelve with original score. An immersive fantasy listening experience. Running time: 14h 30m.',
  //   ),
  //   MarketplaceListing(
  //     id: 'm20',
  //     title: 'The Code of Forgotten Stars',
  //     authorName: 'Eleanor Voss',
  //     price: '\$8.49',
  //     type: ListingType.audio,
  //     rating: 4.5,
  //     reviewCount: 196,
  //     contentCategory: ContentCategory.novel,
  //     genre: Genre.mystery,
  //     description:
  //         'A slow-burn audio mystery read by the author herself. A cryptographer receives a manuscript written in a code only she can break — but solving it may cost her everything. Running time: 6h 48m.',
  //   ),
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
