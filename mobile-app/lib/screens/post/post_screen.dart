import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';

/// Args bundle for [PostScreen] navigation. Pass via [GoRoute.extra] to
/// pre-populate the editor — used by the Home "Upload from device" flow to
/// land the user on the post screen with their file already attached.
class PostScreenArgs {
  // AUDIO DISABLED (2026-09-30): book/e-book only for now.
  // final bool startWithAudio;
  final String? initialTitle;
  final String? initialContent;
  final String? uploadedFileName;
  // final String? uploadedAudioName; // Audio disabled
  const PostScreenArgs({
    // this.startWithAudio = false, // Audio disabled
    this.initialTitle,
    this.initialContent,
    this.uploadedFileName,
    // this.uploadedAudioName, // Audio disabled
  });
}

class PostScreen extends ConsumerStatefulWidget {
  // final bool startWithAudio; // Audio disabled
  final String? initialTitle;
  final String? initialContent;
  final String? uploadedFileName;
  // final String? uploadedAudioName; // Audio disabled

  const PostScreen({
    super.key,
    // this.startWithAudio = false, // Audio disabled
    this.initialTitle,
    this.initialContent,
    this.uploadedFileName,
    // this.uploadedAudioName, // Audio disabled
  });

  factory PostScreen.fromArgs(PostScreenArgs args) => PostScreen(
    // startWithAudio: args.startWithAudio, // Audio disabled
    initialTitle: args.initialTitle,
    initialContent: args.initialContent,
    uploadedFileName: args.uploadedFileName,
    // uploadedAudioName: args.uploadedAudioName, // Audio disabled
  );

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  ContentCategory _selectedCategory = ContentCategory.poem;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocus = FocusNode();
  // bool _hasAudio = false; // Audio disabled
  // String? _audioFileName; // Audio disabled
  String? _coverFileName;
  List<String> _tags = [];
  final List<_PageDraft> _extraPages = [];
  // Reading aids: a contents page listing every page, and automatic page
  // numbers (1, 2, 3… — each page numbered one higher than the last).
  bool _showToc = false;
  bool _showPageNumbers = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.uploadedFileName != null) {
      _coverFileName = widget.uploadedFileName;
    }
    // AUDIO DISABLED (2026-09-30):
    // if (widget.uploadedAudioName != null) {
    //   _audioFileName = widget.uploadedAudioName;
    //   _hasAudio = true;
    // }
    // // Entering via the "Audio" option → prompt to pick an audio file straight away.
    // if (widget.startWithAudio && widget.uploadedAudioName == null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) _pickAudio();
    //   });
    // }
    // Live word count / reading-time caption below the content field.
    _contentController.addListener(() => setState(() {}));
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    for (final page in _extraPages) {
      page.dispose();
    }
    super.dispose();
  }

  /// Appends a new page. If the previous page (or the main title, for the
  /// first added page) has a visible title, asks whether to keep showing
  /// that same title on the new page too.
  Future<void> _addPage() async {
    final refTitle = _extraPages.isEmpty
        ? _titleController.text.trim()
        : (_extraPages.last.showTitle
              ? _extraPages.last.titleController.text.trim()
              : '');

    var showTitle = false;
    var initialTitle = '';
    if (refTitle.isNotEmpty) {
      final keep = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'Add page',
            style: AppFonts.display(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Show "$refTitle" as the title on this page too?',
            style: AppFonts.ui(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No title'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, keep it'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (keep ?? false) {
        showTitle = true;
        initialTitle = refTitle;
      }
    }

    setState(() {
      _extraPages.add(
        _PageDraft(showTitle: showTitle, initialTitle: initialTitle),
      );
    });
  }

  void _removePage(int index) {
    setState(() {
      _extraPages.removeAt(index).dispose();
    });
  }

  /// Wraps the current content selection in [token] (e.g. `**` for bold). With
  /// no selection, inserts an empty pair and drops the caret between them.
  void _wrapInline(String token) {
    final text = _contentController.text;
    var sel = _contentController.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);

    final selected = text.substring(sel.start, sel.end);
    final newText = text.replaceRange(
      sel.start,
      sel.end,
      '$token$selected$token',
    );
    final newSel = selected.isEmpty
        ? TextSelection.collapsed(offset: sel.start + token.length)
        : TextSelection(
            baseOffset: sel.start + token.length,
            extentOffset: sel.end + token.length,
          );

    _contentController.value = _contentController.value.copyWith(
      text: newText,
      selection: newSel,
      composing: TextRange.empty,
    );
    _contentFocus.requestFocus();
  }

  /// Toggles a line [prefix] (e.g. `"> "` for quote, `"- "` for bullets) on
  /// every line touched by the selection.
  void _toggleLinePrefix(String prefix) {
    final text = _contentController.text;
    var sel = _contentController.selection;
    if (!sel.isValid) sel = TextSelection.collapsed(offset: text.length);

    final lineStart = sel.start == 0
        ? 0
        : text.lastIndexOf('\n', sel.start - 1) + 1;
    var lineEnd = text.indexOf('\n', sel.end);
    if (lineEnd == -1) lineEnd = text.length;

    final lines = text.substring(lineStart, lineEnd).split('\n');
    final allPrefixed = lines.every(
      (l) => l.trim().isEmpty || l.startsWith(prefix),
    );
    final newBlock = lines
        .map((l) {
          if (l.trim().isEmpty) return l;
          if (allPrefixed) {
            return l.startsWith(prefix) ? l.substring(prefix.length) : l;
          }
          return l.startsWith(prefix) ? l : '$prefix$l';
        })
        .join('\n');

    _contentController.value = _contentController.value.copyWith(
      text: text.replaceRange(lineStart, lineEnd, newBlock),
      selection: TextSelection.collapsed(offset: lineStart + newBlock.length),
      composing: TextRange.empty,
    );
    _contentFocus.requestFocus();
  }

  // AUDIO DISABLED (2026-09-30):
  // Future<void> _pickAudio() async {
  //   final result = await FilePicker.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
  //     withData: false,
  //   );
  //   if (!mounted) return;
  //   if (result != null && result.files.isNotEmpty) {
  //     setState(() {
  //       _audioFileName = result.files.single.name;
  //       _hasAudio = true;
  //     });
  //   }
  // }
  //
  // void _removeAudio() => setState(() {
  //   _audioFileName = null;
  //   _hasAudio = false;
  // });

  Future<void> _pickCover() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: false,
    );
    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      setState(() => _coverFileName = result.files.single.name);
    }
  }

  void _removeCover() => setState(() => _coverFileName = null);

  // Pick any file from device storage and fold its contents into the editor.
  // .txt → read into title (filename) + body.
  // Anything else (PDF, image, doc) → attached as a cover/file reference.
  // file.path is null on web, so we silently skip text reading there.
  Future<void> _pickAndFillFromFile() async {
    final result = await FilePicker.pickFiles(withData: false);
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final name = file.name;
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
    final baseTitle = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;

    // const audioExts = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'}; // Audio disabled

    String? textContent;
    if (ext == 'txt' && file.path != null) {
      try {
        textContent = await File(file.path!).readAsString();
      } catch (_) {
        textContent = null;
      }
    }
    if (!mounted) return;

    setState(() {
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = baseTitle;
      }
      if (textContent != null && _contentController.text.trim().isEmpty) {
        _contentController.text = textContent;
      }
      // AUDIO DISABLED (2026-09-30): audio files are no longer attachable.
      // if (audioExts.contains(ext)) {
      //   _audioFileName = name;
      //   _hasAudio = true;
      // } else if (ext != 'txt') {
      if (ext != 'txt') {
        _coverFileName = name;
      }
    });
  }

  Future<void> _editTags() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _TagsDialog(initial: _tags),
    );
    if (result != null) setState(() => _tags = result);
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a title and content before publishing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final author = ref.read(currentUserProvider);
    if (author == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need a profile to publish'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final pages = _extraPages
        .map(
          (p) => PostPage(
            title: p.showTitle && p.titleController.text.trim().isNotEmpty
                ? p.titleController.text.trim()
                : null,
            content: p.contentController.text.trim(),
          ),
        )
        .where((p) => p.content.isNotEmpty)
        .toList();
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      createdAt: DateTime.now(),
      // AUDIO DISABLED (2026-09-30):
      // audioUrl: _hasAudio
      //     ? (_audioFileName ?? 'audio/user_recording.mp3')
      //     : null,
      coverImageUrl: _coverFileName,
      pages: pages,
      // A contents page only makes sense once there are pages to list.
      showTableOfContents: _showToc && pages.isNotEmpty,
      showPageNumbers: _showPageNumbers,
    );
    // Capture the (root) messenger before popping so the sync-failure snack
    // can still be shown after this screen is gone.
    final messenger = ScaffoldMessenger.of(context);
    final synced = ref.read(postsNotifierProvider.notifier).addPost(newPost);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        // Audio disabled: content: Text(_hasAudio ? 'Audio posted! 🎙️' : 'Post published! ✨'),
        content: const Text('Post published! ✨'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          // Audio disabled: widget.startWithAudio ? 'New Audio' : 'New Post',
          'New Post',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                // accentOnFill (darker than accent) + explicit white
                // foreground keeps this at WCAG AA contrast in both themes.
                backgroundColor: isDark
                    ? AppColors.darkAccentOnFill
                    : AppColors.accentOnFill,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              onPressed: _publish,
              child: Text(
                'Publish',
                style: AppFonts.ui(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _CategorySelector(
              selected: _selectedCategory,
              isDark: isDark,
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: AppFonts.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: AppFonts.display(
                  fontSize: 20,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            const SizedBox(height: 12),
            _FormatBar(
              isDark: isDark,
              onWrap: _wrapInline,
              onPrefix: _toggleLinePrefix,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              maxLines: null,
              minLines: 12,
              keyboardType: TextInputType.multiline,
              style: AppFonts.reading(
                fontSize: 16,
                height: 1.8,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing...',
                hintStyle: AppFonts.reading(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            if (_wordCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$_wordCount word${_wordCount == 1 ? '' : 's'} · '
                    '~${(_wordCount / 200).ceil().clamp(1, 999)} min read',
                    style: AppFonts.ui(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            const SizedBox(height: 12),
            Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _AttachmentRow(
              // hasAudio: _hasAudio, // Audio disabled
              // audioFileName: _audioFileName, // Audio disabled
              coverFileName: _coverFileName,
              tagCount: _tags.length,
              isDark: isDark,
              // onAudioTap: _hasAudio ? _removeAudio : _pickAudio, // Audio disabled
              onCoverTap: _coverFileName != null ? _removeCover : _pickCover,
              onTagsTap: _editTags,
              onUploadTap: _pickAndFillFromFile,
            ),
            const SizedBox(height: 20),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pages', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addPage,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add page'),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_extraPages.isNotEmpty)
                  _AttachmentChip(
                    icon: _showToc
                        ? Icons.check_circle_rounded
                        : Icons.toc_rounded,
                    label: 'Contents page',
                    active: _showToc,
                    isDark: isDark,
                    onTap: () => setState(() => _showToc = !_showToc),
                  ),
                _AttachmentChip(
                  icon: _showPageNumbers
                      ? Icons.check_circle_rounded
                      : Icons.format_list_numbered_rounded,
                  label: 'Page numbers',
                  active: _showPageNumbers,
                  isDark: isDark,
                  onTap: () =>
                      setState(() => _showPageNumbers = !_showPageNumbers),
                ),
              ],
            ),
            if (_showPageNumbers)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Pages are numbered automatically — each page one higher '
                  'than the last.',
                  style: AppFonts.ui(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  ),
                ),
              ),
            for (var i = 0; i < _extraPages.length; i++)
              _PageEditor(
                index: i,
                page: _extraPages[i],
                isDark: isDark,
                onRemove: () => _removePage(i),
                onToggleTitle: () => setState(
                  () => _extraPages[i].showTitle = !_extraPages[i].showTitle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mutable draft state for one additional page while composing a post.
class _PageDraft {
  final TextEditingController titleController;
  final TextEditingController contentController;
  bool showTitle;

  _PageDraft({required this.showTitle, String initialTitle = ''})
    : titleController = TextEditingController(text: initialTitle),
      contentController = TextEditingController();

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}

/// Editor card for one additional page: optional title (toggle on/off) plus
/// content. The writer decides per page whether a title shows at all.
class _PageEditor extends StatelessWidget {
  final int index;
  final _PageDraft page;
  final bool isDark;
  final VoidCallback onRemove;
  final VoidCallback onToggleTitle;

  const _PageEditor({
    required this.index,
    required this.page,
    required this.isDark,
    required this.onRemove,
    required this.onToggleTitle,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final fill = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Page ${index + 2}',
                style: AppFonts.ui(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: page.showTitle
                    ? 'Hide title on this page'
                    : 'Show title on this page',
                icon: Icon(
                  page.showTitle ? Icons.title_rounded : Icons.title_outlined,
                  size: 18,
                  color: page.showTitle ? AppColors.accent : mutedColor,
                ),
                onPressed: onToggleTitle,
              ),
              IconButton(
                tooltip: 'Remove page',
                icon: Icon(Icons.close_rounded, size: 18, color: mutedColor),
                onPressed: onRemove,
              ),
            ],
          ),
          if (page.showTitle)
            TextField(
              controller: page.titleController,
              style: AppFonts.display(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: 'Page title',
                hintStyle: AppFonts.display(color: mutedColor),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          TextField(
            controller: page.contentController,
            maxLines: null,
            minLines: 3,
            style: AppFonts.reading(
              fontSize: 14,
              height: 1.6,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Page content...',
              hintStyle: AppFonts.reading(color: mutedColor),
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final ContentCategory selected;
  final bool isDark;
  final ValueChanged<ContentCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ContentCategory.values.map((cat) {
          final isSelected = cat == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${cat.emoji} ${cat.label}',
                  style: AppFonts.ui(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Formatting toolbar shown above the content editor. Inline buttons wrap the
/// current selection; the quote / bullet buttons toggle a line prefix.
class _FormatBar extends StatelessWidget {
  final bool isDark;
  final void Function(String token) onWrap;
  final void Function(String prefix) onPrefix;

  const _FormatBar({
    required this.isDark,
    required this.onWrap,
    required this.onPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _FormatButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              color: fg,
              onTap: () => onWrap('**'),
            ),
            _FormatButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              color: fg,
              onTap: () => onWrap('*'),
            ),
            _FormatButton(
              icon: Icons.format_underlined_rounded,
              tooltip: 'Underline',
              color: fg,
              onTap: () => onWrap('__'),
            ),
            _FormatButton(
              icon: Icons.strikethrough_s_rounded,
              tooltip: 'Strikethrough',
              color: fg,
              onTap: () => onWrap('~~'),
            ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: dividerColor,
            ),
            _FormatButton(
              icon: Icons.format_quote_rounded,
              tooltip: 'Quote',
              color: fg,
              onTap: () => onPrefix('> '),
            ),
            _FormatButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet list',
              color: fg,
              onTap: () => onPrefix('- '),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  // final bool hasAudio; // Audio disabled
  // final String? audioFileName; // Audio disabled
  final String? coverFileName;
  final int tagCount;
  final bool isDark;
  // final VoidCallback onAudioTap; // Audio disabled
  final VoidCallback onCoverTap;
  final VoidCallback onTagsTap;
  final VoidCallback onUploadTap;

  const _AttachmentRow({
    // required this.hasAudio, // Audio disabled
    // required this.audioFileName, // Audio disabled
    required this.coverFileName,
    required this.tagCount,
    required this.isDark,
    // required this.onAudioTap, // Audio disabled
    required this.onCoverTap,
    required this.onTagsTap,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = coverFileName != null;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _AttachmentChip(
          icon: Icons.upload_file_rounded,
          label: 'Upload file',
          active: false,
          isDark: isDark,
          onTap: onUploadTap,
        ),
        // AUDIO DISABLED (2026-09-30):
        // _AttachmentChip(
        //   icon: hasAudio ? Icons.check_circle_rounded : Icons.mic_rounded,
        //   label: hasAudio ? (audioFileName ?? 'Audio added') : 'Add audio',
        //   active: hasAudio,
        //   isDark: isDark,
        //   onTap: onAudioTap,
        // ),
        _AttachmentChip(
          icon: hasCover ? Icons.check_circle_rounded : Icons.image_outlined,
          label: hasCover ? (coverFileName ?? 'Cover added') : 'Add cover',
          active: hasCover,
          isDark: isDark,
          onTap: onCoverTap,
        ),
        _AttachmentChip(
          icon: Icons.tag_rounded,
          label: tagCount > 0
              ? '$tagCount tag${tagCount == 1 ? '' : 's'}'
              : 'Add tags',
          active: tagCount > 0,
          isDark: isDark,
          onTap: onTagsTap,
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _AttachmentChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.15)
              : (isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? AppColors.accent
                  : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.ui(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppColors.accent
                    : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagsDialog extends StatefulWidget {
  final List<String> initial;
  const _TagsDialog({required this.initial});

  @override
  State<_TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends State<_TagsDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial.join(', '),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    final tags = _c.text
        .split(',')
        .map((t) => t.trim().replaceFirst(RegExp(r'^#+'), '').trim())
        .where((t) => t.isNotEmpty)
        .toList();
    Navigator.pop(context, tags);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.surfaceVariant;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return AlertDialog(
      title: Text(
        'Add tags',
        style: AppFonts.display(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            autofocus: true,
            style: AppFonts.ui(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: 'poetry, grief, sunday',
              hintStyle: AppFonts.ui(fontSize: 14, color: mutedColor),
              filled: true,
              fillColor: fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Separate tags with commas',
            style: AppFonts.ui(fontSize: 11, color: mutedColor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.darkAccentOnFill
                : AppColors.accentOnFill,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
