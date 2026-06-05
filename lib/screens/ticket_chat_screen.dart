import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/services/api_service.dart';

class TicketChatScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketChatScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;
  late Map<String, dynamic> _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = Map<String, dynamic>.from(widget.ticket);
  }

  Future<void> _submitReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final success = await ApiService().replySupportTicket(_ticket['_id'], message);

    if (success) {
      // Optimistically add reply
      final newReply = {
        'message': message,
        'from': 'user',
        'createdAt': DateTime.now().toIso8601String(),
      };
      setState(() {
        _ticket['replies'] = List.from(_ticket['replies'] ?? [])..add(newReply);
      });
      _replyController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reply')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _ticket['status'] ?? 'open';
    final List replies = _ticket['replies'] ?? [];
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Ticket Chat",
              style: TextStyle(
                color: AppColors.bluegray,
                fontSize: AppFontStyles.fontSize_AppBar,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: status == 'open' ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10.r),
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
          ],
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  children: [
                    // Original Message
                    _buildMessageBubble(
                      message: _ticket['message'] ?? '',
                      fromUser: true,
                      dateStr: _ticket['createdAt'],
                      isInitial: true,
                    ),
                    
                    // Replies
                    ...replies.map((reply) => _buildMessageBubble(
                      message: reply['message'] ?? '',
                      fromUser: reply['from'] == 'user',
                      dateStr: reply['createdAt'],
                      isInitial: false,
                    )),
                  ],
                ),
              ),
              
              // Input Area
              if (status == 'open')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFBBE0ED), width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25.r),
                            border: Border.all(color: const Color(0xFFBBE0ED)),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: TextStyle(
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontSize: 14.sp,
                              color: AppColors.bluegray,
                            ),
                            decoration: InputDecoration(
                              hintText: "Type a reply...",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitReply,
                        child: Container(
                          width: 45.w,
                          height: 45.w,
                          decoration: BoxDecoration(
                            color: AppColors.blueWaterIntake,
                            shape: BoxShape.circle,
                          ),
                          child: _isSubmitting
                              ? Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message, 
    required bool fromUser, 
    required String? dateStr,
    required bool isInitial,
  }) {
    final date = dateStr != null ? DateTime.tryParse(dateStr)?.toLocal() : null;
    final timeString = date != null ? "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}" : "";
    
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        mainAxisAlignment: fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromUser)
            Container(
              margin: EdgeInsets.only(right: 10.w),
              width: 30.w,
              height: 30.w,
              child: Image.asset("assets/ticket_support_icon.png"),
            ),
            
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: fromUser ? AppColors.blueWaterIntake : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(fromUser ? 20.r : 5.r),
                  bottomRight: Radius.circular(fromUser ? 5.r : 20.r),
                ),
                border: fromUser ? null : Border.all(color: const Color(0xFFBBE0ED)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isInitial && fromUser)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        "Initial Issue",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [AppFontStyles.boldFontVariation],
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: fromUser ? Colors.white : AppColors.bluegray,
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                    ),
                  ),
                  if (timeString.isNotEmpty) ...[
                    SizedBox(height: 5.h),
                    Text(
                      timeString,
                      style: TextStyle(
                        color: fromUser ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                        fontSize: 10.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (fromUser)
            Container(
              margin: EdgeInsets.only(left: 10.w),
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppColors.blueWaterIntake.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: AppColors.blueWaterIntake, size: 16.sp),
            ),
        ],
      ),
    );
  }
}
