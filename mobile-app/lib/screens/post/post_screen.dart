import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';

/// Args bundle for [PostScreen] navigation. Pass via [GoRoute.extra] to
/// pre-populate the editor — used by the Home "Upload from device" flow to
/// land the user on the post screen with their file already attached.
class PostScreenArgs {
  final bool startWithAudio;
  final String? initialTitle;
  final String? initialContent;
  final String? uploadedFileName;
  final String? uploadedAudioName;
  const PostScreenArgs({
    this.startWithAudio = false,
    this.initialTitle,
    this.initialContent,
    this.uploadedFileName,
    this.uploadedAudioName,
  });
}

class PostScreen extends ConsumerStatefulWidget {
  final bool startWithAudio;
  final String? initialTitle;
  final String? initialContent;
  final String? uploadedFileName;
  final String? uploadedAudioName;

  const PostScreen({
    super.key,
    this.startWithAudio = false,
    this.initialTitle,
    this.initialContent,
    this.uploadedFileName,
    this.uploadedAudioName,
  });

  factory PostScreen.fromArgs(PostScreenArgs args) => PostScreen(
        startWithAudio: args.startWithAudio,
        initialTitle: args.initialTitle,
        initialContent: args.initialContent,
        uploadedFileName: args.uploadedFileName,
        uploadedAudioName: args.uploadedAudioName,
      );

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  ContentCategory _selectedCategory = ContentCategory.poem;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentFocus = FocusNode();
  bool _hasAudio = false;
  String? _audioFileName;
  String? _coverFileName;
  List<String> _tags = [];
  final List<_PageDraft> _extraPages = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialContent != null) _contentController.text = widget.initialContent!;
    if (widget.uploadedFileName != null) {
      _coverFileName = widget.uploadedFileName;
    }
    if (widget.uploadedAudioName != null) {
      _audioFileName = widget.uploadedAudioName;
      _hasAudio = true;
    }
    // Entering via the "Audio" option → prompt to pick an audio file straight away.
    if (widget.startWithAudio && widget.uploadedAudioName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickAudio();
      });
    }
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
          title: Text('Add page',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
          content: Text('Show "$refTitle" as the title on this page too?',
              style: GoogleFonts.lato(fontSize: 14)),
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
      _extraPages.add(_PageDraft(showTitle: showTitle, initialTitle: initialTitle));
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
    final newText = text.replaceRange(sel.start, sel.end, '$token$selected$token');
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

    final lineStart =
        sel.start == 0 ? 0 : text.lastIndexOf('\n', sel.start - 1) + 1;
    var lineEnd = text.indexOf('\n', sel.end);
    if (lineEnd == -1) lineEnd = text.length;

    final lines = text.substring(lineStart, lineEnd).split('\n');
    final allPrefixed =
        lines.every((l) => l.trim().isEmpty || l.startsWith(prefix));
    final newBlock = lines.map((l) {
      if (l.trim().isEmpty) return l;
      if (allPrefixed) {
        return l.startsWith(prefix) ? l.substring(prefix.length) : l;
      }
      return l.startsWith(prefix) ? l : '$prefix$l';
    }).join('\n');

    _contentController.value = _contentController.value.copyWith(
      text: text.replaceRange(lineStart, lineEnd, newBlock),
      selection: TextSelection.collapsed(offset: lineStart + newBlock.length),
      composing: TextRange.empty,
    );
    _contentFocus.requestFocus();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      withData: false,
    );
    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _audioFileName = result.files.single.name;
        _hasAudio = true;
      });
    }
  }

  void _removeAudio() => setState(() {
        _audioFileName = null;
        _hasAudio = false;
      });

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
  // .txt → read into title (filename) + body. Audio → attached as audio.
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

    const audioExts = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'};

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
      if (audioExts.contains(ext)) {
        _audioFileName = name;
        _hasAudio = true;
      } else if (ext != 'txt') {
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
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
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
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      createdAt: DateTime.now(),
      audioUrl: _hasAudio
          ? (_audioFileName ?? 'audio/user_recording.mp3')
          : null,
      coverImageUrl: _coverFileName,
      pages: _extraPages
          .map((p) => PostPage(
                title: p.showTitle && p.titleController.text.trim().isNotEmpty
                    ? p.titleController.text.trim()
                    : null,
                content: p.contentController.text.trim(),
              ))
          .where((p) => p.content.isNotEmpty)
          .toList(),
    );
    // Capture the (root) messenger before popping so the sync-failure snack
    // can still be shown after this screen is gone.
    final messenger = ScaffoldMessenger.of(context);
    final synced = ref.read(postsNotifierProvider.notifier).addPost(newPost);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_hasAudio ? 'Audio posted! 🎙️' : 'Post published! ✨'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (!await synced) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Saved locally — couldn't sync to server"),
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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.startWithAudio ? 'New Audio' : 'New Post',
            style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                // accentOnFill (darker than accent) + explicit white
                // foreground keeps this at WCAG AA contrast in both themes.
                backgroundColor:
                    isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: _publish,
              child: Text('Publish', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
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
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: GoogleFonts.playfairDisplay(
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
              style: GoogleFonts.lora(
                fontSize: 16,
                height: 1.8,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing...',
                hintStyle: GoogleFonts.lora(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
            const SizedBox(height: 12),
            Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _AttachmentRow(
              hasAudio: _hasAudio,
              audioFileName: _audioFileName,
              coverFileName: _coverFileName,
              tagCount: _tags.length,
              isDark: isDark,
              onAudioTap: _hasAudio ? _removeAudio : _pickAudio,
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
            for (var i = 0; i < _extraPages.length; i++)
              _PageEditor(
                index: i,
                page: _extraPages[i],
                isDark: isDark,
                onRemove: () => _removePage(i),
                onToggleTitle: () => setState(
                    () => _extraPages[i].showTitle = !_extraPages[i].showTitle),
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
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final fill = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

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
              Text('Page ${index + 2}',
                  style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700, color: mutedColor)),
              const Spacer(),
              IconButton(
                tooltip: page.showTitle ? 'Hide title on this page' : 'Show title on this page',
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
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: 'Page title',
                hintStyle: GoogleFonts.playfairDisplay(color: mutedColor),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          TextField(
            controller: page.contentController,
            maxLines: null,
            minLines: 3,
            style: GoogleFonts.lora(fontSize: 14, height: 1.6, color: textColor),
            decoration: InputDecoration(
              hintText: 'Page content...',
              hintStyle: GoogleFonts.lora(color: mutedColor),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${cat.emoji} ${cat.label}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
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
                onTap: () => onWrap('**')),
            _FormatButton(
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic',
                color: fg,
                onTap: () => onWrap('*')),
            _FormatButton(
                icon: Icons.format_underlined_rounded,
                tooltip: 'Underline',
                color: fg,
                onTap: () => onWrap('__')),
            _FormatButton(
                icon: Icons.strikethrough_s_rounded,
                tooltip: 'Strikethrough',
                color: fg,
                onTap: () => onWrap('~~')),
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
                onTap: () => onPrefix('> ')),
            _FormatButton(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Bullet list',
                color: fg,
                onTap: () => onPrefix('- ')),
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
  final bool hasAudio;
  final String? audioFileName;
  final String? coverFileName;
  final int tagCount;
  final bool isDark;
  final VoidCallback onAudioTap;
  final VoidCallback onCoverTap;
  final VoidCallback onTagsTap;
  final VoidCallback onUploadTap;

  const _AttachmentRow({
    required this.hasAudio,
    required this.audioFileName,
    required this.coverFileName,
    required this.tagCount,
    required this.isDark,
    required this.onAudioTap,
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
        _AttachmentChip(
          icon: hasAudio ? Icons.check_circle_rounded : Icons.mic_rounded,
          label: hasAudio ? (audioFileName ?? 'Audio added') : 'Add audio',
          active: hasAudio,
          isDark: isDark,
          onTap: onAudioTap,
        ),
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
              : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.accent : (isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.accent : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
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
  late final TextEditingController _c =
      TextEditingController(text: widget.initial.join(', '));

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
    final fill =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return AlertDialog(
      title: Text('Add tags',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            autofocus: true,
            style: GoogleFonts.lato(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: 'poetry, grief, sunday',
              hintStyle: GoogleFonts.lato(fontSize: 14, color: mutedColor),
              filled: true,
              fillColor: fill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Text('Separate tags with commas',
              style: GoogleFonts.lato(fontSize: 11, color: mutedColor)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
