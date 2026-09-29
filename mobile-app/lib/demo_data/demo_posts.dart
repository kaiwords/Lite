// Demo/sample posts — used only as a first-launch local seed until the real
// Supabase data loads (see PostsNotifier.loadFromSupabase in
// providers/feed_provider.dart) and by tests. Not otherwise referenced by
// the running app.
import '../models/post.dart';
import '../models/user.dart';

final mockPosts = [
  Post(
    id: 'p1',
    author: mockUsers[0],
    title: 'Between the Lines',
    content:
        'There is a language\nthat lives between the words —\nin the pause before a name is spoken,\nin the breath after a door has closed.\n\nI have been learning it my whole life,\nthis tongue of silences,\nthis grammar of the almost-said.\n\nSome days I am fluent.\nOther days, I cannot even begin.',
    category: ContentCategory.poem,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likesCount: 234,
    commentsCount: 18,
    sharesCount: 42,
    isLiked: true,
    // Audio disabled: audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    // Audio disabled: linkedListingId: 'm9', // Audio Book in Marketplace
  ),
  Post(
    id: 'p2',
    author: mockUsers[2],
    title: 'Why We Read Alone But Feel Together',
    content:
        'There is something paradoxical about reading. It is the most solitary of activities — just you, the page, and the dim lamplight. And yet, at the end of every great book, you feel as though you have spent time with company. Real company. The kind that changes you.\n\nThis is the miracle literature performs quietly, without fanfare: it dissolves the self long enough for you to inhabit another\'s consciousness entirely.',
    category: ContentCategory.article,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    likesCount: 891,
    commentsCount: 67,
    sharesCount: 203,
    // Audio disabled: audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    // Audio disabled: linkedListingId: 'm10', // Audio Book in Marketplace
  ),
  Post(
    id: 'p3',
    author: mockUsers[1],
    title: 'My Wi-Fi Password',
    content:
        'My therapist told me to set boundaries.\nSo I changed my Wi-Fi password\nto my ex\'s name.\n\nNow every time someone asks for it\nI have to say:\n"It\'s complicated."',
    category: ContentCategory.joke,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    likesCount: 1204,
    commentsCount: 94,
    sharesCount: 512,
    isLiked: true,
    isFavourited: true,
    // Audio disabled: audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ),
  Post(
    id: 'p4',
    author: mockUsers[3],
    title: 'Morning Without You',
    content:
        'Coffee grows cold.\nYour chair still holds your shape —\nI do not sit there.',
    category: ContentCategory.haiku,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likesCount: 567,
    commentsCount: 33,
    sharesCount: 88,
    // Audio disabled: audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    // Audio disabled: linkedListingId: 'm12', // Audio Book in Marketplace
  ),
  Post(
    id: 'p7',
    author: mockUsers[3],
    title: 'The Ember Throne',
    content:
        'The letter arrived on a morning that smelled of rain and old iron.\n\n'
        'Sera did not open it at first. Letters from the capital had a weight '
        'that ordinary envelopes could not contain — as though the parchment '
        'itself had absorbed the ambitions of every hand it passed through.\n\n'
        'She set it on the windowsill and brewed tea instead.',
    category: ContentCategory.book,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    likesCount: 528,
    commentsCount: 41,
    sharesCount: 93,
    linkedListingId: 'mBook1',
    bookId: 'b1',
  ),
  Post(
    id: 'p5',
    author: mockUsers[0],
    title: 'The Glass House — Chapter One',
    content:
        'The town of Belcroft had one rule everyone knew but no one said aloud: you did not look at the Glass House after dark.\n\nRosalind had been breaking rules her whole life, which is perhaps why, on the night of her twenty-third birthday, she found herself standing on the hill above town, staring directly at the structure that no one dared name.',
    category: ContentCategory.novel,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    likesCount: 412,
    commentsCount: 51,
    sharesCount: 76,
    isFavourited: true,
    linkedListingId: 'm1', // Physical Book in Marketplace
  ),
  Post(
    id: 'p6',
    author: mockUsers[2],
    title: 'On Solitude and the Creative Mind',
    content:
        'Every artist knows the particular agony of the empty page. But what we talk about less is the gift that lives inside that emptiness — if you are willing to sit with it long enough.\n\nSolitude is not loneliness. Loneliness is the ache of absence. Solitude is the discovery of presence: your own, undiluted.',
    category: ContentCategory.essay,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    likesCount: 723,
    commentsCount: 45,
    sharesCount: 134,
    // Audio disabled: audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
  ),
];
