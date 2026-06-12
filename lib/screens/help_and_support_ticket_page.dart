import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';

class HelpAndSupportTicketPage extends StatefulWidget {
  const HelpAndSupportTicketPage({super.key});

  @override
  State<HelpAndSupportTicketPage> createState() =>
      _HelpAndSupportTicketPageState();
}

class _HelpAndSupportTicketPageState extends State<HelpAndSupportTicketPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  
  int _currentTab = 0; // 0 for My Tickets, 1 for New Ticket
  
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoadingTickets = false;

  final List<String> _topics = [
    "Hydration Syncing",
    "UV-C Activation",
    "Battery & Charging",
    "App Connectivity"
  ];
  
  final Set<String> _selectedTopics = {};
  
  StreamSubscription<void>? _ticketUpdateSub;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _ticketUpdateSub = FirebaseMessagingService.ticketUpdateStream.stream.listen((_) {
      if (mounted) _fetchTickets();
    });
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoadingTickets = true;
    });
    
    final userId = await SharedPrefsHelper.getUserId();
    if (userId != null && userId.isNotEmpty) {
      final tickets = await ApiService().getSupportTickets(userId);
      if (mounted && tickets != null) {
        setState(() {
          _tickets = tickets;
        });
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoadingTickets = false;
      });
    }
  }

  void _onTopicTapped(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
        String currentText = _messageController.text;
        _messageController.text = currentText.replaceAll("$topic\n", "");
      } else {
        _selectedTopics.add(topic);
        if (_messageController.text.isNotEmpty && !_messageController.text.endsWith("\n")) {
          _messageController.text += "\n";
        }
        _messageController.text += "$topic\n";
      }
    });
  }

  Future<void> _submitTicket() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a message or select a topic.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final userId = await SharedPrefsHelper.getUserId();
    if (userId != null && userId.isNotEmpty) {
      bool success = await ApiService().submitSupportTicket(userId, message);
      if (success) {
        Fluttertoast.showToast(msg: "Ticket submitted successfully!");
        _messageController.clear();
        _selectedTopics.clear();
        await _fetchTickets();
        setState(() {
          _currentTab = 0; // Switch to My Tickets tab (now index 0)
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to submit ticket. Try again.");
      }
    } else {
      Fluttertoast.showToast(msg: "User not identified.");
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _ticketUpdateSub?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Help & Support",
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: AppFontStyles.fontSize_AppBar,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset("assets/images/back_ic.svg"),
        ),
      ),
      body: Container(
        width: AppDimensions.dim1.sw,
        height: AppDimensions.dim1.sh,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/app_background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _currentTab = 0);
                          _fetchTickets();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: _currentTab == 0 ? AppColors.blueWaterIntake : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "My Tickets",
                            style: TextStyle(
                              color: _currentTab == 0 ? Colors.white : AppColors.bluegray,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentTab = 1),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: _currentTab == 1 ? AppColors.blueWaterIntake : Colors.transparent,
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "New Ticket",
                            style: TextStyle(
                              color: _currentTab == 1 ? Colors.white : AppColors.bluegray,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _currentTab == 0 ? _buildMyTicketsTab() : _buildNewTicketTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                child: Image.asset("assets/ticket_support_icon.png"),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChatBubble(
                      title: "What seems to be the trouble?",
                      subtitle: "Our team is here to help you get back to your flow.",
                    ),
                    SizedBox(height: 15.h),
                    _buildChatBubble(
                      title: "I can help with that! Here are some common things I can assist with:",
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 25.h),
          
          Padding(
            padding: EdgeInsets.only(left: 55.w),
            child: Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: _topics.map((topic) {
                final isSelected = _selectedTopics.contains(topic);
                return GestureDetector(
                  onTap: () => _onTopicTapped(topic),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blueWaterIntake : const Color(0xFFE8F4F8),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? AppColors.blueWaterIntake : const Color(0xFFBBE0ED),
                      ),
                    ),
                    child: Text(
                      topic,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.bluegray,
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 30.h),
          
          Text(
            "Or type your message",
            style: TextStyle(
              color: AppColors.bluegray,
              fontSize: 16.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: const Color(0xFFBBE0ED), width: 1.5),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontSize: 14.sp,
                color: AppColors.bluegray,
              ),
              decoration: InputDecoration(
                hintText: "Type your message here...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(15.w),
              ),
            ),
          ),
          
          SizedBox(height: 30.h),
          
          SizedBox(
            width: double.infinity,
            height: 55.h,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueWaterIntake,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Submit Ticket",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    if (_isLoadingTickets) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.blueWaterIntake),
      );
    }
    
    if (_tickets.isEmpty) {
      return Center(
        child: Text(
          "You have no support tickets.",
          style: TextStyle(
            color: AppColors.bluegray,
            fontSize: 16.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        final status = ticket['status'] ?? 'open';
        final replies = (ticket['replies'] as List?) ?? [];
        
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(
              '/ticket_chat',
              arguments: ticket,
            ).then((_) => _fetchTickets()); // refresh on back
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 15.h),
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: const Color(0xFFBBE0ED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: status == 'open' ? Colors.green.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'open' ? Colors.green.shade700 : Colors.grey.shade700,
                          fontSize: 10.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(ticket['createdAt']),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  ticket['message'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: 14.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation],
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 14.sp, color: Colors.grey.shade400),
                    SizedBox(width: 5.w),
                    Text(
                      "${replies.length} replies",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.fontWeightVariation600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '';
    }
  }

  Widget _buildChatBubble({required String title, String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        border: Border.all(color: const Color(0xFFBBE0ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.bluegray,
              fontSize: 16.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 10.h),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.darkgray,
                fontSize: 12.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                height: 1.5,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
