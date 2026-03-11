import 'package:flutter/material.dart';

import '../../widgets/desktop_sidebar.dart';
import '../../widgets/responsive_layout.dart';
import '../chat/empty_chat_view.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _selectedChatId;

  void _onChatSelected(String chatId) {
    setState(() {
      _selectedChatId = chatId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The HomeScreen acts as our master list
    final home = HomeScreen(
      selectedChatId: _selectedChatId,
      onChatSelected: _onChatSelected,
    );

    return ResponsiveLayout(
      mobileLayout: home,
      masterLayout: HomeScreen(
        selectedChatId: _selectedChatId,
        onChatSelected: _onChatSelected,
        showProfileAvatar: false, // The desktop sidebar handles this now
      ),
      sideNavigationLayout: const DesktopSidebar(),
      detailLayout: _selectedChatId == null
          ? const EmptyChatView()
          : Center(child: Text('Chat $_selectedChatId')), // Placeholder
    );
  }
}
