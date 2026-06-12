import 'package:flutter/material.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _messages = [];
  String? _userId;
  late BottomNavCubit _bottomNavCubit;

  @override
  void initState() {
    super.initState();
    _bottomNavCubit = context.read<BottomNavCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bottomNavCubit.hideBar();
      }
    });
    _fetchMessages();
  }

  @override
  void dispose() {
    _bottomNavCubit.showBar();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      if (_userId != null) {
        final data = await _apiService.getUserMessages(_userId!);
        if (data['data'] != null && data['data']['messages'] != null) {
          setState(() {
            _messages = data['data']['messages'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(dynamic message) async {
    if (message['isRead'] == true) return;
    try {
      await _apiService.markMessageRead(message['_id']);
      setState(() {
        message['isRead'] = true;
      });
    } catch (e) {
      debugPrint("Error marking message as read: $e");
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'update':
        return Icons.system_update_alt;
      case 'achievement':
        return Icons.emoji_events;
      case 'goal':
        return Icons.water_drop;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'update':
        return Colors.blue;
      case 'achievement':
        return Colors.amber;
      case 'goal':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        _bottomNavCubit.showBar();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _bottomNavCubit.showBar();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            "Inbox",
            style: TextStyle(
              color: AppColors.bluegray,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [FontVariation('wght', 700)],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.black),
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blueWaterIntake))
          : _messages.isEmpty
              ? Center(
                  child: Text(
                    "No new messages",
                    style: TextStyle(
                      color: AppColors.bluegray,
                      fontSize: 16,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isRead = message['isRead'] == true;
                    final type = message['type'] ?? 'system';

                    if (type == 'update') {
                      return _buildUpdateCard(message, isRead);
                    }

                    return Card(
                      elevation: 0,
                      color: isRead ? Colors.white : AppColors.blueWaterIntake.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isRead ? Colors.grey.shade200 : AppColors.blueWaterIntake.withOpacity(0.2),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _markAsRead(message),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getColorForType(type).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getIconForType(type),
                                      color: _getColorForType(type),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                message['title'] ?? '',
                                                style: TextStyle(
                                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppColors.black,
                                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.blueWaterIntake,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          message['body'] ?? '',
                                          style: TextStyle(
                                            color: AppColors.bluegray,
                                            fontSize: 14,
                                            height: 1.4,
                                            fontFamily: AppFontStyles.urbanistFontFamily,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> message, bool isRead) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : AppColors.blueWaterIntake.withOpacity(0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _markAsRead(message),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Area
            Image.asset(
              AssetsPath.newRelease,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
            // Content Area
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message['title'] ?? '',
                          style: TextStyle(
                            color: AppColors.bluegray,
                            fontSize: 20,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.blueWaterIntake,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Released recently",
                    style: TextStyle(
                      color: AppColors.bluegray.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message['body'] ?? '',
                    style: TextStyle(
                      color: AppColors.bluegray.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.boldFontVariation],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {},
                      child: Text(
                        "Update Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          fontSize: 15,
                        ),
                      ),
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
