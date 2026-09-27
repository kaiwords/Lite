import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/marketplace.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/cover_image.dart';

// Curated deep-toned palette for the "design a cover" mode — borrows the
// same saturated colors Genre already uses for gradient tiles/heroes
// elsewhere, so a designed cover reads consistently with the rest of the
// marketplace.
const _coverDesignColors = [
  Color(0xFF3D2B6B), // fantasy purple
  Color(0xFF8B2E45), // romance rose
  Color(0xFF0D3559), // sci-fi blue
  Color(0xFF1A1A35), // mystery indigo
  Color(0xFF2D0D0D), // horror red-black
  Color(0xFF4A3518), // historical brown
  Color(0xFF0D3530), // literary teal
  Color(0xFF4A3568), // poetry violet
  Color(0xFF2D4A1A), // self-help green
  Color(0xFF2D3D4A), // biography slate
  Color(0xFF4A2D0D), // thriller amber
  Color(0xFF8B6800), // humor gold
];

// ─────────────────────────────────────────────────────────────────────────────
// "List a Book" sell-flow full-screen form + its write-online editor.
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the "List a Book" screen. [initialType] pre-selects the listing
/// format (e.g. E-Book or Audio) when launching from elsewhere, such as the
/// Home upload action.
void showListItemSheet(
  BuildContext context, {
  ListingType? initialType,
  MarketplaceListing? existing,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ListItemSheet(
        isDark: isDark,
        initialType: initialType,
        existing: existing,
      ),
    ),
  );
}

class ListItemSheet extends ConsumerStatefulWidget {
  final bool isDark;
  final MarketplaceListing? existing; // non-null = edit mode
  final ListingType? initialType; // pre-selected format for new listings
  const ListItemSheet({
    super.key,
    required this.isDark,
    this.existing,
    this.initialType,
  });

  @override
  ConsumerState<ListItemSheet> createState() => _ListItemSheetState();
}

class _ListItemSheetState extends ConsumerState<ListItemSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descriptionCtrl;
  late ListingType _type;
  late ContentCategory _category;

  // Book metadata — shown for Physical and E-Book listings only.
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _publisherCtrl;
  DateTime? _publicationDate;

  // Physical-copy-only fields.
  ListingCondition? _condition;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _editionCtrl;
  final Set<ShippingMethod> _shippingMethods = {};
  late final TextEditingController _pickupLocationCtrl;
  late final TextEditingController _pickupPhoneCtrl;
  late final TextEditingController _meetupLocationCtrl;
  late final TextEditingController _meetupPhoneCtrl;
  late ListingOffer _offer;
  late final TextEditingController _swapWantedForCtrl;

  // Cover art — a picked photo takes precedence over the designed
  // (color + title/author/decorative-line) cover when both are set.
  String? _coverImagePath;
  Color? _coverColor;

  // E-book source
  _EbookSource _ebookSource = _EbookSource.pdf;
  String? _pdfFileName;
  List<EbookChapter> _ebookChapters = [];

  // Audio book source — one uploaded file per volume, each with an editable
  // seller-chosen title.
  List<AudioVolume> _audioVolumes = [];
  final List<TextEditingController> _volumeTitleCtrls = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _priceCtrl = TextEditingController(
      text: e != null ? e.price.replaceAll('\$', '') : '',
    );
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _isbnCtrl = TextEditingController(text: e?.isbn ?? '');
    _publisherCtrl = TextEditingController(text: e?.publisher ?? '');
    _publicationDate = e?.publicationDate;
    _condition = e?.condition;
    _quantityCtrl = TextEditingController(
      text: e?.quantity != null ? e!.quantity.toString() : '',
    );
    _editionCtrl = TextEditingController(text: e?.edition ?? '');
    _shippingMethods.addAll(e?.shippingMethods ?? const []);
    _pickupLocationCtrl = TextEditingController(text: e?.pickupLocation ?? '');
    _pickupPhoneCtrl = TextEditingController(text: e?.pickupPhone ?? '');
    _meetupLocationCtrl = TextEditingController(text: e?.meetupLocation ?? '');
    _meetupPhoneCtrl = TextEditingController(text: e?.meetupPhone ?? '');
    _offer = e?.offer ?? ListingOffer.sale;
    _swapWantedForCtrl = TextEditingController(text: e?.swapWantedFor ?? '');
    _type = e?.type ?? widget.initialType ?? ListingType.ebook;
    _category = e?.contentCategory ?? ContentCategory.novel;
    _coverImagePath = e?.coverImageUrl;
    _coverColor = e?.coverColor != null ? Color(e!.coverColor!) : null;
    _pdfFileName = e?.pdfFileName;
    _ebookChapters = List.of(e?.ebookChapters ?? const []);
    if (_ebookChapters.isEmpty &&
        (e?.ebookContent?.trim().isNotEmpty ?? false)) {
      // Legacy single-blob listings are migrated into a single chapter the
      // moment they're opened for editing, so they can keep being extended
      // through the chapter builder without losing what was already written.
      _ebookChapters = [
        EbookChapter(title: 'Chapter 1', content: e!.ebookContent!.trim()),
      ];
    }
    _audioVolumes = List.of(e?.audioVolumes ?? const []);
    _volumeTitleCtrls.addAll(
      _audioVolumes.map((v) => TextEditingController(text: v.title)),
    );
    // Pick the source tab that matches whatever was already provided
    _ebookSource = _ebookChapters.isNotEmpty
        ? _EbookSource.write
        : _EbookSource.pdf;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _isbnCtrl.dispose();
    _publisherCtrl.dispose();
    _quantityCtrl.dispose();
    _editionCtrl.dispose();
    _pickupLocationCtrl.dispose();
    _pickupPhoneCtrl.dispose();
    _meetupLocationCtrl.dispose();
    _meetupPhoneCtrl.dispose();
    _swapWantedForCtrl.dispose();
    for (final c in _volumeTitleCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        setState(() => _coverImagePath = path);
      }
    }
  }

  Future<void> _pickPublicationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _publicationDate ?? now,
      firstDate: DateTime(1500),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _publicationDate = picked);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pdfFileName = result.files.single.name);
    }
  }

  /// Picks an audio file from local storage. Appends it as a new volume, or
  /// replaces the volume at [replaceIndex] when re-uploading (its title is
  /// left untouched on replace — only the file changes).
  Future<void> _pickAudioVolume({int? replaceIndex}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      withData: false,
    );
    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      final name = result.files.single.name;
      setState(() {
        if (replaceIndex != null && replaceIndex < _audioVolumes.length) {
          _audioVolumes[replaceIndex] = AudioVolume(
            title: _audioVolumes[replaceIndex].title,
            fileName: name,
          );
        } else {
          final title = 'Volume ${_audioVolumes.length + 1}';
          _audioVolumes.add(AudioVolume(title: title, fileName: name));
          _volumeTitleCtrls.add(TextEditingController(text: title));
        }
      });
    }
  }

  Future<void> _openChapters() async {
    final result = await Navigator.of(context).push<List<EbookChapter>>(
      MaterialPageRoute(
        builder: (_) => _ChapterListScreen(
          bookTitle: _titleCtrl.text.trim(),
          initialChapters: _ebookChapters,
        ),
      ),
    );
    if (result != null) {
      setState(() => _ebookChapters = result);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Free/Swap Physical listings cost nothing — the Price field is hidden
    // for them, so there's nothing to parse or validate.
    final isFreeOrSwap =
        _type == ListingType.physical && _offer != ListingOffer.sale;
    double price = 0;
    if (!isFreeOrSwap) {
      final priceRaw = _priceCtrl.text.trim();
      if (priceRaw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all fields.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final parsed = double.tryParse(
        priceRaw.replaceAll('\$', '').replaceAll(',', ''),
      );
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid price.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      price = parsed;
    }

    // For E-Books, require either an uploaded PDF or at least one written
    // chapter with some content in it.
    final isEbook = _type == ListingType.ebook;
    final pdfName = isEbook && _ebookSource == _EbookSource.pdf
        ? _pdfFileName
        : null;
    final chapters = isEbook && _ebookSource == _EbookSource.write
        ? _ebookChapters
              .where((c) => c.content.trim().isNotEmpty)
              .toList(growable: false)
        : const <EbookChapter>[];
    if (isEbook && pdfName == null && chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload a PDF or write your book to list an E-Book.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For Audio books, require at least one uploaded volume.
    final isAudio = _type == ListingType.audio;
    final audioVolumes = isAudio
        ? [
            for (var i = 0; i < _audioVolumes.length; i++)
              AudioVolume(
                title: _volumeTitleCtrls[i].text.trim().isEmpty
                    ? 'Volume ${i + 1}'
                    : _volumeTitleCtrls[i].text.trim(),
                fileName: _audioVolumes[i].fileName,
              ),
          ]
        : const <AudioVolume>[];
    if (isAudio && audioVolumes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload at least one audio volume to list an Audio book.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Physical-only quantity, validated only when a value was actually typed
    // (it's optional — sellers who don't set it just aren't tracked for stock).
    final isPhysical = _type == ListingType.physical;
    int? quantity;
    if (isPhysical && _quantityCtrl.text.trim().isNotEmpty) {
      quantity = int.tryParse(_quantityCtrl.text.trim());
      if (quantity == null || quantity < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid quantity (1 or more).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // ISBN/publisher/publication date are book-metadata fields, relevant to
    // Physical and E-Book listings but not a pure Audio listing.
    final showBookMeta = isPhysical || isEbook;
    final isbn = showBookMeta && _isbnCtrl.text.trim().isNotEmpty
        ? _isbnCtrl.text.trim()
        : null;
    final publisher = showBookMeta && _publisherCtrl.text.trim().isNotEmpty
        ? _publisherCtrl.text.trim()
        : null;
    final publicationDate = showBookMeta ? _publicationDate : null;
    final edition = isPhysical && _editionCtrl.text.trim().isNotEmpty
        ? _editionCtrl.text.trim()
        : null;

    // Delivery needs nothing extra, but Pickup and Meetup each need
    // seller-entered details so a buyer knows where (and, for Pickup, how)
    // to actually get the book.
    String? pickupLocation;
    String? pickupPhone;
    if (isPhysical && _shippingMethods.contains(ShippingMethod.pickup)) {
      pickupLocation = _pickupLocationCtrl.text.trim();
      pickupPhone = _pickupPhoneCtrl.text.trim();
      if (pickupLocation.isEmpty || pickupPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a pickup location and phone number for Pickup.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    String? meetupLocation;
    String? meetupPhone;
    if (isPhysical && _shippingMethods.contains(ShippingMethod.meetup)) {
      meetupLocation = _meetupLocationCtrl.text.trim();
      meetupPhone = _meetupPhoneCtrl.text.trim();
      if (meetupLocation.isEmpty || meetupPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a meetup location and phone number for Meet Up.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final e = widget.existing;
    final listing = MarketplaceListing(
      id: e?.id ?? 'u${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      // New listings are attributed to the signed-in profile, not a mock name.
      authorName:
          e?.authorName ?? ref.read(currentUserProvider)?.displayName ?? '',
      price: isFreeOrSwap ? _offer.label : '\$${price.toStringAsFixed(2)}',
      priceCents: isFreeOrSwap ? 0 : (price * 100).round(),
      type: _type,
      rating: e?.rating ?? 0,
      reviewCount: e?.reviewCount ?? 0,
      linkedPostId: e?.linkedPostId,
      contentCategory: _category,
      genre: e?.genre,
      description: _descriptionCtrl.text.trim(),
      isbn: isbn,
      publisher: publisher,
      publicationDate: publicationDate,
      condition: isPhysical ? _condition : null,
      quantity: quantity,
      edition: edition,
      shippingMethods: isPhysical ? _shippingMethods.toList() : const [],
      pickupLocation: pickupLocation,
      pickupPhone: pickupPhone,
      meetupLocation: meetupLocation,
      meetupPhone: meetupPhone,
      offer: isPhysical ? _offer : ListingOffer.sale,
      swapWantedFor: isPhysical && _offer == ListingOffer.swap
          ? _swapWantedForCtrl.text.trim()
          : null,
      // Preserved from the existing listing on edit (only the claim-listing
      // Edge Function ever sets this true) — never reset by re-saving.
      isSoldOut: e?.isSoldOut ?? false,
      pdfFileName: pdfName,
      // Chapters supersede the legacy flat blob going forward — once a
      // listing is edited through this sheet it's saved in the new format.
      ebookContent: null,
      ebookChapters: chapters,
      audioVolumes: audioVolumes,
      coverImageUrl: _coverImagePath,
      coverColor: _coverColor?.toARGB32(),
    );
    // Capture the (root) messenger before popping so the sync-failure snack
    // can still be shown after the sheet is gone.
    final messenger = ScaffoldMessenger.of(context);
    final synced = _isEdit
        ? ref.read(myListingsProvider.notifier).update(listing)
        : ref.read(myListingsProvider.notifier).add(listing);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? '"$title" updated' : '"$title" listed for sale!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (!await synced) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Saved on this device. Couldn't sync to the server."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Listing' : 'List a Book',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEdit
                  ? 'Update your listing details'
                  : 'Your listing will appear in the marketplace',
              style: AppFonts.ui(fontSize: 13, color: labelColor),
            ),
            const SizedBox(height: 20),

            // Title
            _FieldLabel('Title', isDark: isDark),
            const SizedBox(height: 6),
            _TextField(
              controller: _titleCtrl,
              hint: 'e.g. Midnight Verses',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Description
            _FieldLabel('Description', isDark: isDark),
            const SizedBox(height: 6),
            _TextField(
              controller: _descriptionCtrl,
              hint: 'What is this book about?',
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Cover — a picked photo, or a designed color + title/author +
            // decorative-line cover (this is what actually renders behind
            // the book's cover page and its listing tiles).
            _FieldLabel('Cover', isDark: isDark),
            const SizedBox(height: 8),
            AnimatedBuilder(
              // Keeps the live preview's title text in sync as the seller
              // types, without needing a setState wired through _TextField.
              animation: _titleCtrl,
              builder: (context, _) => _CoverPicker(
                title: _titleCtrl.text,
                authorName:
                    widget.existing?.authorName ??
                    ref.watch(currentUserProvider)?.displayName ??
                    '',
                imagePath: _coverImagePath,
                color: _coverColor,
                isDark: isDark,
                onPickPhoto: _pickCoverPhoto,
                onRemovePhoto: () => setState(() => _coverImagePath = null),
                onPickColor: (c) => setState(() => _coverColor = c),
              ),
            ),
            const SizedBox(height: 16),

            // Type
            _FieldLabel('Type', isDark: isDark),
            const SizedBox(height: 8),
            Row(
              children: ListingType.values.map((t) {
                final sel = _type == t;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.badgeColor.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? t.badgeColor : borderColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              t.icon,
                              size: 20,
                              color: sel ? t.badgeColor : labelColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.label,
                              style: AppFonts.ui(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: sel ? t.badgeColor : labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Book details — ISBN, publisher, publication date. Relevant to
            // Physical and E-Book listings; a pure Audio listing skips them.
            if (_type == ListingType.physical ||
                _type == ListingType.ebook) ...[
              _FieldLabel('ISBN', isDark: isDark),
              const SizedBox(height: 6),
              _TextField(
                controller: _isbnCtrl,
                hint: 'e.g. 978-3-16-148410-0',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Publisher', isDark: isDark),
              const SizedBox(height: 6),
              _TextField(
                controller: _publisherCtrl,
                hint: 'e.g. Penguin Books',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Publication Date', isDark: isDark),
              const SizedBox(height: 6),
              _DatePickerField(
                date: _publicationDate,
                isDark: isDark,
                onTap: _pickPublicationDate,
              ),
              const SizedBox(height: 16),
            ],

            // Physical-copy-only fields — condition, quantity, edition.
            if (_type == ListingType.physical) ...[
              _FieldLabel('Condition', isDark: isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ListingCondition.values.map((c) {
                  final sel = _condition == c;
                  return GestureDetector(
                    onTap: () => setState(() => _condition = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: sel ? AppColors.accent : borderColor,
                        ),
                      ),
                      child: Text(
                        c.label,
                        style: AppFonts.ui(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? AppColors.accent : labelColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _FieldLabel('Quantity Available', isDark: isDark),
              const SizedBox(height: 6),
              _TextField(
                controller: _quantityCtrl,
                hint: 'e.g. 1',
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Edition / Language', isDark: isDark),
              const SizedBox(height: 6),
              _TextField(
                controller: _editionCtrl,
                hint: 'e.g. 1st Edition, English',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Shipping Methods', isDark: isDark),
              const SizedBox(height: 4),
              Text(
                'How can buyers get this copy from you?',
                style: AppFonts.ui(fontSize: 11, color: labelColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ShippingMethod.values.map((m) {
                  final sel = _shippingMethods.contains(m);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) {
                        _shippingMethods.remove(m);
                      } else {
                        _shippingMethods.add(m);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: sel ? AppColors.accent : borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            m.icon,
                            size: 14,
                            color: sel ? AppColors.accent : labelColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m.label,
                            style: AppFonts.ui(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? AppColors.accent : labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Delivery needs nothing extra. Pickup needs where/how to
              // reach the seller; Meetup needs a general meeting area (the
              // buyer still suggests a specific place/time per order).
              if (_shippingMethods.contains(ShippingMethod.pickup)) ...[
                const SizedBox(height: 12),
                _FieldLabel('Pickup Location', isDark: isDark),
                const SizedBox(height: 6),
                _TextField(
                  controller: _pickupLocationCtrl,
                  hint: 'e.g. 123 Main St, Springfield',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FieldLabel('Pickup Phone Number', isDark: isDark),
                const SizedBox(height: 6),
                _TextField(
                  controller: _pickupPhoneCtrl,
                  hint: 'e.g. (555) 123-4567',
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),
              ],
              if (_shippingMethods.contains(ShippingMethod.meetup)) ...[
                const SizedBox(height: 12),
                _FieldLabel('Meetup Location', isDark: isDark),
                const SizedBox(height: 6),
                _TextField(
                  controller: _meetupLocationCtrl,
                  hint: 'e.g. Downtown, near the library',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FieldLabel('Meetup Phone Number', isDark: isDark),
                const SizedBox(height: 6),
                _TextField(
                  controller: _meetupPhoneCtrl,
                  hint: 'e.g. (555) 123-4567',
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 16),
            ],

            // E-Book content — upload a PDF or write the book online
            if (_type == ListingType.ebook) ...[
              _FieldLabel('E-Book Content', isDark: isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SourceToggle(
                      label: 'Upload PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      selected: _ebookSource == _EbookSource.pdf,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _ebookSource = _EbookSource.pdf),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SourceToggle(
                      label: 'Write online',
                      icon: Icons.edit_note_rounded,
                      selected: _ebookSource == _EbookSource.write,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _ebookSource = _EbookSource.write),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_ebookSource == _EbookSource.pdf)
                _FileUploadBox(
                  fileName: _pdfFileName,
                  isDark: isDark,
                  onPick: _pickPdf,
                  onClear: () => setState(() => _pdfFileName = null),
                  fileIcon: Icons.picture_as_pdf_rounded,
                  fileIconColor: const Color(0xFFC0392B),
                  emptyTitle: 'Tap to upload PDF',
                  emptyHint: 'Choose a .pdf file from your device',
                  attachedLabel: 'PDF attached',
                )
              else
                _ChaptersBox(
                  chapters: _ebookChapters,
                  isDark: isDark,
                  onTap: _openChapters,
                ),
              const SizedBox(height: 16),
            ],

            // Audio book — upload one file per volume (1 is fine, add more)
            if (_type == ListingType.audio) ...[
              Row(
                children: [
                  _FieldLabel(
                    _audioVolumes.length > 1 ? 'Audio Volumes' : 'Audio File',
                    isDark: isDark,
                  ),
                  const Spacer(),
                  if (_audioVolumes.isNotEmpty)
                    Text(
                      '${_audioVolumes.length} ${_audioVolumes.length == 1 ? 'volume' : 'volumes'}',
                      style: AppFonts.ui(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_audioVolumes.isEmpty)
                _FileUploadBox(
                  fileName: null,
                  isDark: isDark,
                  onPick: () => _pickAudioVolume(),
                  onClear: () {},
                  fileIcon: Icons.audiotrack_rounded,
                  fileIconColor: ListingType.audio.badgeColor,
                  emptyTitle: 'Tap to upload audio',
                  emptyHint: 'MP3, M4A, AAC, WAV, OGG or FLAC',
                  attachedLabel: 'Audio attached',
                )
              else ...[
                for (var i = 0; i < _audioVolumes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _VolumeTile(
                      volumeNumber: i + 1,
                      titleController: _volumeTitleCtrls[i],
                      fileName: _audioVolumes[i].fileName,
                      isDark: isDark,
                      onReplace: () => _pickAudioVolume(replaceIndex: i),
                      onRemove: () => setState(() {
                        _audioVolumes.removeAt(i);
                        _volumeTitleCtrls.removeAt(i).dispose();
                      }),
                    ),
                  ),
                _AddVolumeButton(
                  isDark: isDark,
                  onTap: () => _pickAudioVolume(),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Category
            _FieldLabel('Category', isDark: isDark),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    [
                      ContentCategory.novel,
                      ContentCategory.poem,
                      ContentCategory.essay,
                      ContentCategory.story,
                      ContentCategory.haiku,
                      ContentCategory.article,
                      ContentCategory.joke,
                    ].map((cat) {
                      final sel = _category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: sel ? AppColors.accent : borderColor,
                              ),
                            ),
                            child: Text(
                              '${cat.emoji} ${cat.label}',
                              style: AppFonts.ui(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : labelColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Offer — a Physical copy can be sold, given away, or offered
            // as a swap instead. E-Book/Audio are always For Sale (a
            // pickup/meetup exchange doesn't apply to digital content).
            if (_type == ListingType.physical) ...[
              _FieldLabel('Offer', isDark: isDark),
              const SizedBox(height: 8),
              Row(
                children: ListingOffer.values.map((o) {
                  final sel = _offer == o;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _offer = o),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? AppColors.accent : borderColor,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                o.icon,
                                size: 20,
                                color: sel ? AppColors.accent : labelColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o.label,
                                style: AppFonts.ui(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? AppColors.accent : labelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Price — hidden for Free/Swap, which cost nothing.
            if (_type != ListingType.physical ||
                _offer == ListingOffer.sale) ...[
              _FieldLabel('Price (USD)', isDark: isDark),
              const SizedBox(height: 6),
              _TextField(
                controller: _priceCtrl,
                hint: 'e.g. 9.99',
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefix: Text(
                  '\$ ',
                  style: AppFonts.ui(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],

            // What the seller wants in return — Swap only, optional (blank
            // means "open to offers").
            if (_type == ListingType.physical &&
                _offer == ListingOffer.swap) ...[
              _FieldLabel('What would you like in exchange?', isDark: isDark),
              const SizedBox(height: 6),
              _TextField(
                controller: _swapWantedForCtrl,
                hint: 'e.g. Another mystery novel, or open to offers',
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              // accentOnFill (darker than accent) keeps the white label
              // at WCAG AA contrast.
              backgroundColor: isDark
                  ? AppColors.darkAccentOnFill
                  : AppColors.accentOnFill,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _submit,
            child: Text(
              _isEdit ? 'Save Changes' : 'List for Sale',
              style: AppFonts.ui(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Publication date picker field
// ─────────────────────────────────────────────────────────────────────────────

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final bool isDark;
  final VoidCallback onTap;
  const _DatePickerField({
    required this.date,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final label = date == null
        ? 'Select a date'
        : '${_monthNames[date!.month - 1]} ${date!.day}, ${date!.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: mutedColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppFonts.ui(
                fontSize: 14,
                color: date == null ? mutedColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// E-book source widgets (PDF upload vs write online)
// ─────────────────────────────────────────────────────────────────────────────

enum _EbookSource { pdf, write }

class _SourceToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _SourceToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.accent : borderColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.accent : labelColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.ui(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileUploadBox extends StatelessWidget {
  final String? fileName;
  final bool isDark;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final IconData fileIcon;
  final Color fileIconColor;
  final String emptyTitle;
  final String emptyHint;
  final String attachedLabel;
  const _FileUploadBox({
    required this.fileName,
    required this.isDark,
    required this.onPick,
    required this.onClear,
    required this.fileIcon,
    required this.fileIconColor,
    required this.emptyTitle,
    required this.emptyHint,
    required this.attachedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    if (fileName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(fileIcon, size: 24, color: fileIconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    attachedLabel,
                    style: AppFonts.ui(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onPick,
              child: Text(
                'Replace',
                style: AppFonts.ui(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
              tooltip: 'Remove',
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 30,
              color: AppColors.accent,
            ),
            const SizedBox(height: 8),
            Text(
              emptyTitle,
              style: AppFonts.ui(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              emptyHint,
              style: AppFonts.ui(fontSize: 11, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audiobook volume tile + add-volume button ───────────────────────────────

class _VolumeTile extends StatelessWidget {
  final int volumeNumber;
  final TextEditingController titleController;
  final String fileName;
  final bool isDark;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  const _VolumeTile({
    required this.volumeNumber,
    required this.titleController,
    required this.fileName,
    required this.isDark,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final audioColor = ListingType.audio.badgeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: audioColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.audiotrack_rounded, size: 18, color: audioColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: AppFonts.ui(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Volume $volumeNumber',
                    hintStyle: AppFonts.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.ui(fontSize: 11, color: mutedColor),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onReplace,
            child: Text(
              'Replace',
              style: AppFonts.ui(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
            tooltip: 'Remove volume',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddVolumeButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _AddVolumeButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Add another volume',
              style: AppFonts.ui(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChaptersBox extends StatelessWidget {
  final List<EbookChapter> chapters;
  final bool isDark;
  final VoidCallback onTap;
  const _ChaptersBox({
    required this.chapters,
    required this.isDark,
    required this.onTap,
  });

  int get _totalWords {
    var total = 0;
    for (final c in chapters) {
      final t = c.content.trim();
      if (t.isEmpty) continue;
      total += t.split(RegExp(r'\s+')).length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final hasContent = chapters.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasContent ? Icons.auto_stories_rounded : Icons.edit_note_rounded,
              size: 28,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasContent ? 'Continue writing' : 'Write your book',
                    style: AppFonts.ui(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasContent
                        ? '${chapters.length} ${chapters.length == 1 ? 'chapter' : 'chapters'} · $_totalWords ${_totalWords == 1 ? 'word' : 'words'}'
                        : 'Build your book chapter by chapter',
                    style: AppFonts.ui(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
            Text(
              hasContent ? 'Edit' : 'Open',
              style: AppFonts.ui(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover picker — photo upload + "design a cover" color palette, with a live
// preview matching the actual cover the book reader will show.
// ─────────────────────────────────────────────────────────────────────────────

class _CoverPicker extends StatelessWidget {
  final String title;
  final String authorName;
  final String? imagePath;
  final Color? color;
  final bool isDark;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final ValueChanged<Color> onPickColor;

  const _CoverPicker({
    required this.title,
    required this.authorName,
    required this.imagePath,
    required this.color,
    required this.isDark,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onPickColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CoverPreview(
          title: title,
          authorName: authorName,
          imagePath: imagePath,
          color: color ?? _coverDesignColors.first,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onPickPhoto,
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        imagePath != null ? 'Replace photo' : 'Choose photo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (imagePath != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onRemovePhoto,
                  child: Text(
                    'Remove photo',
                    style: AppFonts.ui(fontSize: 12, color: mutedColor),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Or design a cover',
                style: AppFonts.ui(fontSize: 11, color: labelColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _coverDesignColors.map((c) {
                  final sel = color?.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () => onPickColor(c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Miniature rendering of the actual book-cover design (photo-or-gradient +
/// decorative lines + title + author) so what the seller picks here is
/// exactly what readers will see on the cover page and listing tiles.
class _CoverPreview extends StatelessWidget {
  final String title;
  final String authorName;
  final String? imagePath;
  final Color color;

  const _CoverPreview({
    required this.title,
    required this.authorName,
    required this.imagePath,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final coverImage = coverImageFile(imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        height: 128,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.lerp(color, Colors.black, 0.5)!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            if (coverImage != null)
              Positioned.fill(child: Image.file(coverImage, fit: BoxFit.cover)),
            if (coverImage != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.isEmpty ? 'Your Book Title' : title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const Spacer(),
                  if (authorName.isNotEmpty)
                    Text(
                      authorName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter editor result
// ─────────────────────────────────────────────────────────────────────────────

/// What [_WriteBookScreen] hands back when the seller taps Save: the chapter's
/// (possibly-edited) title alongside its paginated body text.
class _ChapterEditResult {
  final String title;
  final String content;
  const _ChapterEditResult({required this.title, required this.content});
}

// ─────────────────────────────────────────────────────────────────────────────
// Chapter list — build a book chapter by chapter: add, reorder, edit, remove.
// Each chapter's content is written using the same per-chapter editor
// ([_WriteBookScreen]) as the rest of the "write online" flow.
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterListScreen extends StatefulWidget {
  final String bookTitle;
  final List<EbookChapter> initialChapters;
  const _ChapterListScreen({
    required this.bookTitle,
    required this.initialChapters,
  });

  @override
  State<_ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<_ChapterListScreen> {
  late List<EbookChapter> _chapters;

  @override
  void initState() {
    super.initState();
    _chapters = List.of(widget.initialChapters);
  }

  int _wordCount(String s) {
    final t = s.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  Future<void> _addChapter() async {
    final result = await Navigator.of(context).push<_ChapterEditResult>(
      MaterialPageRoute(
        builder: (_) => _WriteBookScreen(
          initialTitle: 'Chapter ${_chapters.length + 1}',
          initialContent: '',
        ),
      ),
    );
    if (result == null) return;
    if (result.title.trim().isEmpty && result.content.trim().isEmpty) return;
    setState(() {
      _chapters.add(
        EbookChapter(
          title: result.title.trim().isEmpty
              ? 'Chapter ${_chapters.length + 1}'
              : result.title.trim(),
          content: result.content,
        ),
      );
    });
  }

  Future<void> _editChapter(int index) async {
    final chapter = _chapters[index];
    final result = await Navigator.of(context).push<_ChapterEditResult>(
      MaterialPageRoute(
        builder: (_) => _WriteBookScreen(
          initialTitle: chapter.title,
          initialContent: chapter.content,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _chapters[index] = EbookChapter(
        title: result.title.trim().isEmpty
            ? chapter.title
            : result.title.trim(),
        content: result.content,
      );
    });
  }

  void _removeChapter(int index) => setState(() => _chapters.removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final chapter = _chapters.removeAt(oldIndex);
      _chapters.insert(newIndex, chapter);
    });
  }

  void _done() => Navigator.pop(context, _chapters);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          widget.bookTitle.isEmpty ? 'Chapters' : widget.bookTitle,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: _done,
            child: Text(
              'Done',
              style: AppFonts.ui(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      body: _chapters.isEmpty
          ? _EmptyChapters(isDark: isDark, onAdd: _addChapter)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _chapters.length,
              onReorder: _reorder,
              itemBuilder: (context, i) => Padding(
                key: ObjectKey(_chapters[i]),
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChapterCard(
                  index: i,
                  chapter: _chapters[i],
                  wordCount: _wordCount(_chapters[i].content),
                  isDark: isDark,
                  onTap: () => _editChapter(i),
                  onRemove: () => _removeChapter(i),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkAccentOnFill
                  : AppColors.accentOnFill,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _addChapter,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add chapter',
              style: AppFonts.ui(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final int index;
  final EbookChapter chapter;
  final int wordCount;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _ChapterCard({
    required this.index,
    required this.chapter,
    required this.wordCount,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.cardBorder;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_indicator_rounded, color: mutedColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title.isEmpty
                        ? 'Chapter ${index + 1}'
                        : chapter.title,
                    style: AppFonts.ui(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$wordCount ${wordCount == 1 ? 'word' : 'words'}',
                    style: AppFonts.ui(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
            tooltip: 'Remove chapter',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _EmptyChapters extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  const _EmptyChapters({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, size: 48, color: mutedColor),
            const SizedBox(height: 12),
            Text(
              'No chapters yet',
              style: AppFonts.ui(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Add chapter" to start writing.',
              textAlign: TextAlign.center,
              style: AppFonts.ui(fontSize: 12, color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Write-online editor — full-screen writing surface for a single chapter
// ─────────────────────────────────────────────────────────────────────────────

class _WriteBookScreen extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  const _WriteBookScreen({
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<_WriteBookScreen> createState() => _WriteBookScreenState();
}

// Formatting uses markdown-style markers (**bold**, _italic_, …). Each chapter
// is a single continuous string, auto-paginated to fit the page shown on screen.

class _WriteBookScreenState extends State<_WriteBookScreen> {
  late final TextEditingController _ctrl;
  late final TextEditingController _chapterTitleCtrl;
  final FocusNode _focus = FocusNode();
  List<String> _pages = [''];
  int _index = 0;
  Size? _pageSize; // measured text area of one page

  TextStyle get _baseStyle => AppFonts.reading(fontSize: 16, height: 1.6);

  @override
  void initState() {
    super.initState();
    _pages = [widget.initialContent];
    _ctrl = TextEditingController(text: _pages[0]);
    _chapterTitleCtrl = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _chapterTitleCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  int get _wordCount {
    final t = _pages.join().trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  // ── Pagination ─────────────────────────────────────────────────────────────

  /// Splits [text] into pages, each holding as much as fits in [size],
  /// breaking on word boundaries where possible.
  List<String> _paginate(String text, Size size) {
    if (text.isEmpty) return [''];
    final pages = <String>[];
    var start = 0;
    while (start < text.length) {
      final remaining = text.substring(start);
      final tp = TextPainter(
        text: TextSpan(text: remaining, style: _baseStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      if (tp.height <= size.height) {
        pages.add(remaining);
        break;
      }

      // How many whole lines fit in the page height?
      final metrics = tp.computeLineMetrics();
      var used = 0.0;
      var lastFit = -1;
      for (var i = 0; i < metrics.length; i++) {
        if (used + metrics[i].height <= size.height) {
          used += metrics[i].height;
          lastFit = i;
        } else {
          break;
        }
      }
      if (lastFit < 0) lastFit = 0;
      var top = 0.0;
      for (var i = 0; i < lastFit; i++) {
        top += metrics[i].height;
      }
      final yMid = top + metrics[lastFit].height / 2;
      final pos = tp.getPositionForOffset(Offset(size.width, yMid));
      var end = start + pos.offset;
      if (end <= start) end = start + 1; // always make progress
      if (end >= text.length) {
        pages.add(text.substring(start));
        break;
      }
      // Prefer a word boundary
      final slice = text.substring(start, end);
      final lastWs = slice.lastIndexOf(RegExp(r'\s'));
      if (lastWs > 0) end = start + lastWs + 1;
      pages.add(text.substring(start, end));
      start = end;
    }
    return pages.isEmpty ? [''] : pages;
  }

  bool _samePages(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Re-flows the whole book after an edit (or page-size change), keeping the
  /// caret in place. New pages are created automatically when content overflows.
  void _reflow({int? cursorOverride}) {
    final size = _pageSize;
    if (size == null) return;

    _pages[_index] = _ctrl.text; // commit the active page
    final full = _pages.join();
    final newPages = _paginate(full, size);

    if (_samePages(newPages, _pages)) {
      setState(() {}); // refresh counters only; leave the caret untouched
      return;
    }

    final before = _pages.take(_index).join().length;
    final sel = _ctrl.selection;
    final globalCursor =
        (cursorOverride ??
                (before +
                    (sel.baseOffset < 0 ? _ctrl.text.length : sel.baseOffset)))
            .clamp(0, full.length);

    var page = 0;
    var local = 0;
    var acc = 0;
    for (var i = 0; i < newPages.length; i++) {
      final len = newPages[i].length;
      if (globalCursor <= acc + len) {
        page = i;
        local = globalCursor - acc;
        if (local == len && i < newPages.length - 1) {
          page = i + 1;
          local = 0;
        }
        break;
      }
      acc += len;
      if (i == newPages.length - 1) {
        page = i;
        local = len;
      }
    }

    setState(() {
      _pages = newPages;
      _index = page;
      _ctrl.value = TextEditingValue(
        text: _pages[page],
        selection: TextSelection.collapsed(
          offset: local.clamp(0, _pages[page].length),
        ),
      );
    });
    _focus.requestFocus();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _pages.length || i == _index) return;
    setState(() {
      _index = i;
      _ctrl.value = TextEditingValue(
        text: _pages[i],
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
    _focus.requestFocus();
  }

  void _save() => Navigator.pop(
    context,
    _ChapterEditResult(
      title: _chapterTitleCtrl.text.trim(),
      content: _pages.join(),
    ),
  );

  // ── Formatting (markdown-style markers) ──────────────────────────────────────

  void _wrap(String left, String right) {
    final value = _ctrl.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final selected = text.substring(start, end);
    final cursor = selected.isEmpty
        ? start + left.length
        : start + left.length + selected.length + right.length;
    _ctrl.value = TextEditingValue(
      text: text.replaceRange(start, end, '$left$selected$right'),
      selection: TextSelection.collapsed(offset: cursor),
    );
    _focus.requestFocus();
    _reflow();
  }

  void _linePrefix(String prefix) {
    final value = _ctrl.value;
    final text = value.text;
    final sel = value.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final lineStart = pos == 0 ? 0 : text.lastIndexOf('\n', pos - 1) + 1;
    _ctrl.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: pos + prefix.length),
    );
    _focus.requestFocus();
    _reflow();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Chapter',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: AppFonts.ui(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chapter title ────────────────────────────────────────────
          Container(
            color: surfaceBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _chapterTitleCtrl,
              style: AppFonts.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Chapter title',
                hintStyle: AppFonts.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: divColor),
          // ── Page bar ───────────────────────────────────────────────────
          Container(
            color: surfaceBg,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous page',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                ),
                Flexible(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _index,
                      isDense: true,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      style: AppFonts.ui(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      items: [
                        for (var i = 0; i < _pages.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              'Page ${i + 1}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) _goTo(v);
                      },
                    ),
                  ),
                ),
                Text(
                  ' of ${_pages.length}',
                  style: AppFonts.ui(fontSize: 13, color: mutedColor),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next page',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: _index < _pages.length - 1
                      ? () => _goTo(_index + 1)
                      : null,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$_wordCount ${_wordCount == 1 ? 'word' : 'words'}',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(fontSize: 12, color: mutedColor),
                  ),
                ),
              ],
            ),
          ),

          // ── Formatting toolbar ─────────────────────────────────────────
          Container(
            color: surfaceBg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _FmtBtn(
                    icon: Icons.format_bold_rounded,
                    tooltip: 'Bold',
                    onTap: () => _wrap('**', '**'),
                  ),
                  _FmtBtn(
                    icon: Icons.format_italic_rounded,
                    tooltip: 'Italic',
                    onTap: () => _wrap('_', '_'),
                  ),
                  _FmtBtn(
                    icon: Icons.format_underlined_rounded,
                    tooltip: 'Underline',
                    onTap: () => _wrap('<u>', '</u>'),
                  ),
                  _FmtBtn(
                    icon: Icons.strikethrough_s_rounded,
                    tooltip: 'Strikethrough',
                    onTap: () => _wrap('~~', '~~'),
                  ),
                  Container(width: 1, height: 22, color: divColor),
                  _FmtBtn(
                    icon: Icons.title_rounded,
                    tooltip: 'Heading',
                    onTap: () => _linePrefix('# '),
                  ),
                  _FmtBtn(
                    icon: Icons.format_list_bulleted_rounded,
                    tooltip: 'Bullet list',
                    onTap: () => _linePrefix('- '),
                  ),
                  _FmtBtn(
                    icon: Icons.format_quote_rounded,
                    tooltip: 'Quote',
                    onTap: () => _linePrefix('> '),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: divColor),

          // ── Editor (one page at a time, auto-paginated) ─────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const margin = 16.0;
                const pad = 18.0;
                final pageW = constraints.maxWidth - margin * 2;
                final pageH = constraints.maxHeight - margin * 2;
                final contentSize = Size(pageW - pad * 2, pageH - pad * 2);

                // (Re)paginate when the page size first becomes known or changes.
                if (_pageSize != contentSize) {
                  final first = _pageSize == null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _pageSize = contentSize;
                    _reflow(cursorOverride: first ? 0 : null);
                  });
                }

                return Center(
                  child: Container(
                    width: pageW,
                    height: pageH,
                    margin: const EdgeInsets.all(margin),
                    padding: const EdgeInsets.all(pad),
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: divColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: (_) => _reflow(),
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: _baseStyle.copyWith(color: textColor),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Start writing page ${_index + 1}…',
                        hintStyle: _baseStyle.copyWith(color: mutedColor),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FmtBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _FmtBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small form helpers used only by this sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.ui(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final int maxLines;
  const _TextField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.keyboardType,
    this.prefix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (prefix != null)
            Padding(padding: const EdgeInsets.only(left: 14), child: prefix!),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: AppFonts.ui(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppFonts.ui(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
