import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes/app_routes.dart';
import '../state/app_scope.dart';
import '../state/cart_controller.dart';
import '../theme/app_theme.dart';
import '../utils/book_filters.dart';
import '../widgets/book_cover.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_pressable.dart';

/// Displays the reader's borrow basket and handles name-validated checkout.
class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.onReturnHome,
    this.embeddedBottomPadding = 0,
  });

  /// When embedded inside the bottom tab bar, switches back to the Discover tab.
  final VoidCallback? onReturnHome;

  /// Extra bottom inset reserved when embedded above the frosted tab bar.
  final double embeddedBottomPadding;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final TextEditingController _nameController;
  String? _nameError;

  bool get _isEmbedded => widget.onReturnHome != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _navigateHome() {
    if (widget.onReturnHome != null) {
      widget.onReturnHome!();
      return;
    }
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.home || route.isFirst,
    );
  }

  Future<void> _handleCheckout(CartController cart) async {
    final result = cart.checkout(_nameController.text);
    if (!result.isSuccess) {
      setState(() => _nameError = result.errorMessage);
      return;
    }

    setState(() => _nameError = null);
    if (!mounted) return;

    final count = result.borrowedCount;
    final noun = count == 1 ? 'book' : 'books';

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Borrowing confirmed'),
        content: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$count $noun marked as borrowed under ${result.borrowerName}.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Back to catalog'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _nameController.clear();
    _navigateHome();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cart = scope.cart;
    final catalog = scope.catalog;
    final library = scope.library;
    final colors = context.bookNestColors;

    return ListenableBuilder(
      listenable: Listenable.merge([cart, catalog, library]),
      builder: (context, _) {
        final items = cart.items;
        final isEmpty = items.isEmpty;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leadingWidth: _isEmbedded ? 0 : 56,
            leading: _isEmbedded
                ? null
                : Center(
                    child: IOSPressable(
                      onTap: () => Navigator.pop(context),
                      pressedScale: 0.88,
                      semanticLabel: 'Back',
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ),
            titleSpacing: _isEmbedded ? 16 : 0,
            title: Text(
              'Borrow basket',
              style: TextStyle(
                color: colors.ink,
                fontSize: _isEmbedded ? 26 : 20,
                fontWeight: _isEmbedded ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            actions: [
              if (!isEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.hairlineBorder),
                      ),
                      child: Text(
                        '${items.length} ${items.length == 1 ? 'book' : 'books'}',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                child: isEmpty
                    ? _EmptyCartView(
                        key: const ValueKey('empty_cart'),
                        bottomPadding: widget.embeddedBottomPadding,
                        onBrowse: _navigateHome,
                      )
                    : _PopulatedCartView(
                        key: const ValueKey('populated_cart'),
                        items: items,
                        readerName: library.readerName,
                        nameController: _nameController,
                        nameError: _nameError,
                        bottomPadding: widget.embeddedBottomPadding,
                        onUseProfileName: () {
                          _nameController.text = library.readerName;
                          _nameController.selection = TextSelection.collapsed(
                            offset: library.readerName.length,
                          );
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                        onNameChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                        onRemove: cart.remove,
                        onConfirm: () => _handleCheckout(cart),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({
    super.key,
    required this.onBrowse,
    required this.bottomPadding,
  });

  final VoidCallback onBrowse;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'Your basket is empty',
            message: 'Add books to start borrowing.',
            actionLabel: 'Browse catalog',
            onAction: onBrowse,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.cardSurface,
            border: Border(top: BorderSide(color: colors.hairlineBorder)),
          ),
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPadding),
            child: const IOSPrimaryButton(
              label: 'Confirm borrowing',
              onPressed: null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PopulatedCartView extends StatelessWidget {
  const _PopulatedCartView({
    super.key,
    required this.items,
    required this.readerName,
    required this.nameController,
    required this.nameError,
    required this.bottomPadding,
    required this.onUseProfileName,
    required this.onNameChanged,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<Book> items;
  final String readerName;
  final TextEditingController nameController;
  final String? nameError;
  final double bottomPadding;
  final VoidCallback onUseProfileName;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onRemove;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final book = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: BookCover(
                          book: book,
                          borderRadius: 8,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatCategoryLabel(book.category),
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IOSPressable(
                        onTap: () => onRemove(book.id),
                        pressedScale: 0.85,
                        semanticLabel: 'Remove ${book.title}',
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: colors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.cardSurface,
            border: Border(top: BorderSide(color: colors.hairlineBorder)),
          ),
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  onChanged: onNameChanged,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onConfirm(),
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: 'Enter borrower name',
                    errorText: nameError,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: colors.mutedText,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IOSPressable(
                      onTap: onUseProfileName,
                      pressedScale: 0.95,
                      semanticLabel: 'Use profile name $readerName',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.softSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.hairlineBorder),
                        ),
                        child: Text(
                          'Use "$readerName"',
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Books are marked borrowed once you confirm.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.mutedText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                IOSPrimaryButton(
                  label: 'Confirm borrowing',
                  onPressed: onConfirm,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
