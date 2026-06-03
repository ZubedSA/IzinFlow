import 'dart:ui';
import 'package:flutter/material.dart';

class CustomNavBarItem {
  final IconData icon;
  final String label;

  CustomNavBarItem({required this.icon, required this.label});
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomNavBarItem> items;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMobile = screenWidth < 600;

    final double outerPadding = isMobile ? 8.0 : 16.0;
    final double itemHorizontalPadding = isSmallScreen ? 10.0 : (isMobile ? 14.0 : 20.0);
    final double itemVerticalPadding = isMobile ? 8.0 : 10.0;
    final double unselectedHorizontalPadding = isSmallScreen ? 6.0 : (isMobile ? 8.0 : 12.0);
    final double iconSize = isMobile ? 20.0 : 24.0;
    final double fontSize = isMobile ? 12.0 : 13.0;
    final double gap = isMobile ? 6.0 : 8.0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: outerPadding, right: outerPadding, bottom: 16.0, top: 8.0),
        child: Container(
          height: isMobile ? 58 : 65,
          decoration: BoxDecoration(
            color: isDarkMode 
                ? theme.colorScheme.surface.withOpacity(0.85) 
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final isSelected = currentIndex == index;
                  final item = items[index];

                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCirc,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? itemHorizontalPadding : unselectedHorizontalPadding,
                        vertical: itemVerticalPadding,
                      ),
                      margin: EdgeInsets.symmetric(vertical: isMobile ? 6.0 : 8.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack), 
                                child: child
                              );
                            },
                            child: Icon(
                              item.icon,
                              key: ValueKey<bool>(isSelected),
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              size: iconSize,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCirc,
                            child: isSelected
                                ? Padding(
                                    padding: EdgeInsets.only(left: gap),
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSize,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
