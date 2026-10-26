import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/navigation_provider.dart';
import '../auth/login_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _sending = false;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  MessageProvider? _msgProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) return;
      _msgProvider = context.read<MessageProvider>();
      _msgProvider!.load(auth.user!.id);
      _msgProvider!.addListener(_onMessagesUpdated);
    });
  }

  @override
  void dispose() {
    _msgProvider?.removeListener(_onMessagesUpdated);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onMessagesUpdated() {
    if (!mounted) return;
    // Only mark seen when this tab is actually visible to the user
    final navIndex = context.read<NavigationProvider>().currentIndex;
    if (navIndex == 1) _msgProvider?.markSeen();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await context.read<MessageProvider>().sendMessage(
        userId: auth.user!.id,
        userName: auth.displayName,
        content: text,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Try again.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final msgProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: _buildAppBar(msgProvider),
      backgroundColor: const Color(0xFFF2F2F2),
      body: !auth.isLoggedIn
          ? _buildLoginPrompt(context)
          : Column(
              children: [
                _buildSupportHeader(),
                const Divider(height: 1),
                Expanded(child: _buildMessageList(msgProvider)),
                _buildInputBar(context, auth),
              ],
            ),
    );
  }

  AppBar _buildAppBar(MessageProvider provider) => AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.navyBlue, AppColors.darkBlue]),
          ),
        ),
        title: const Text('Messages',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (auth.isLoggedIn) {
                provider.load(auth.user!.id, force: true);
              }
            },
          ),
        ],
      );

  Widget _buildLoginPrompt(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: AppColors.lightBlue),
            const SizedBox(height: 16),
            const Text('Sign in to view messages',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey)),
            const SizedBox(height: 8),
            const Text('Log in to chat with ApliMart Support',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );

  Widget _buildSupportHeader() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ApliMart Support',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.navyBlue)),
                Text('Typically replies within a day',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ],
        ),
      );

  Widget _buildMessageList(MessageProvider provider) {
    if (provider.loading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.primaryBlue));
    }
    final messages = provider.messages;
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: AppColors.lightBlue),
            const SizedBox(height: 12),
            const Text('No messages yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey)),
            const SizedBox(height: 6),
            const Text('Send a message to get started',
                style:
                    TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
    );
  }

  Widget _buildInputBar(BuildContext context, AuthProvider auth) =>
      Container(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 8,
          top: 8,
        ),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle:
                      const TextStyle(color: AppColors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.lightBlue, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.lightBlue, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.primaryBlue, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.offWhite,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _sending
                      ? AppColors.grey
                      : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment:
            isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent,
                    color: AppColors.primaryBlue, size: 16),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : AppColors.darkGrey,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
