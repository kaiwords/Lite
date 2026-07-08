class LitUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final double earnings;
  final bool isFollowing;
  final bool isVerified;

  const LitUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.earnings = 0.0,
    this.isFollowing = false,
    this.isVerified = false,
  });

  LitUser copyWith({
    String? username,
    String? displayName,
    String? bio,
    bool? isFollowing,
    int? followersCount,
  }) =>
      LitUser(
        id: id,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl,
        bio: bio ?? this.bio,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount,
        postsCount: postsCount,
        earnings: earnings,
        isFollowing: isFollowing ?? this.isFollowing,
        isVerified: isVerified,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'earnings': earnings,
        'isFollowing': isFollowing,
        'isVerified': isVerified,
      };

  factory LitUser.fromJson(Map<String, dynamic> j) => LitUser(
        id: j['id'] as String,
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        avatarUrl: j['avatarUrl'] as String?,
        bio: (j['bio'] as String?) ?? '',
        followersCount: (j['followersCount'] as num?)?.toInt() ?? 0,
        followingCount: (j['followingCount'] as num?)?.toInt() ?? 0,
        postsCount: (j['postsCount'] as num?)?.toInt() ?? 0,
        earnings: (j['earnings'] as num?)?.toDouble() ?? 0.0,
        isFollowing: (j['isFollowing'] as bool?) ?? false,
        isVerified: (j['isVerified'] as bool?) ?? false,
      );
}

final mockUsers = [
  const LitUser(
    id: 'u1',
    username: 'eleanor_writes',
    displayName: 'Eleanor Voss',
    bio: 'Poet & novelist. Words are my compass.',
    followersCount: 4821,
    followingCount: 312,
    postsCount: 87,
    earnings: 340.50,
    isVerified: true,
  ),
  const LitUser(
    id: 'u2',
    username: 'marcus_ink',
    displayName: 'Marcus Osei',
    bio: 'Short stories & dark fiction enthusiast.',
    followersCount: 2130,
    followingCount: 178,
    postsCount: 54,
    earnings: 127.00,
  ),
  const LitUser(
    id: 'u3',
    username: 'priya_quill',
    displayName: 'Priya Nair',
    bio: 'Essays, articles, and the occasional joke.',
    followersCount: 8960,
    followingCount: 420,
    postsCount: 143,
    earnings: 892.75,
    isVerified: true,
  ),
  const LitUser(
    id: 'u4',
    username: 'javier_poetic',
    displayName: 'Javier Morales',
    bio: 'Bilingual poet. Spanish soul, English words.',
    followersCount: 3200,
    followingCount: 250,
    postsCount: 61,
    earnings: 215.00,
  ),
];
