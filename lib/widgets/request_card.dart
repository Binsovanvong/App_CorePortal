import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core_portal/screens/modules/list/list_view.dart';
import 'package:core_portal/screens/modules/request/request_view.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/pages/Main/main_view.dart';
import '../models/request_model.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

  String getKhmerName(String englishName) {
    switch (englishName) {
      case "Kao Satya":
        return "កៅ សត្យា";
      case "Sorn Sophy":
        return "សន សូភី";
      case "Linda Smith":
        return "លីនដា ស្មីត";
      default:
        return englishName;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine status badge properties
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    if (request.status == "Approved") {
      statusText = "កំពុងស្នាក់នៅ";
      statusBgColor = const Color(0xFFDCFCE7); // Light Green
      statusTextColor = const Color(0xFF16803D); // Dark Green
    } else if (request.status == "Pending") {
      statusText = "បានអនុម័ត";
      statusBgColor = const Color(0xFFE0F2FE); // Light Blue
      statusTextColor = const Color(0xFF0284C7); // Dark Blue
    } else {
      statusText = "រង់ចាំពិនិត្យ";
      statusBgColor = const Color(0xFFF3F4F6); // Light Grey
      statusTextColor = const Color(0xFF4B5563); // Dark Grey
    }

    // Determine subtexts and values
    final isPassport = request.name == "Linda Smith";
    final docTypeSub = isPassport ? "លិខិតឆ្លងដែន" : "អត្តសញ្ញាណប័ណ្ណ";
    final placeType = isPassport ? "ផ្ទះជួល" : "សណ្ឋាគារ";
    final placeSub = request.nationality;
    final dateVal = request.name == "Kao Satya"
        ? "ថ្ងៃទី ០៩, ២០២៦"
        : (request.name == "Sorn Sophy"
              ? "ថ្ងៃទី ១២, ២០២៦"
              : "ថ្ងៃទី ១៥, ២០២៦");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x02000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.person_outline,
                    color: request.gender == "ស្រី"
                        ? const Color(0xffA88400)
                        : const Color(0xFF3B51C5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getKhmerName(request.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${request.name} • ${request.gender}",
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Fields Body (Grid style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldItem(
                        "អត្តសញ្ញាណប័ណ្ណ / លិខិតឆ្លងដែន",
                        request.idNumber,
                        docTypeSub,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldItem(
                        "ប្រភេទទីកន្លែងស្នាក់នៅ",
                        placeType,
                        placeSub,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Column 2
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldItem("ទីតាំង", request.address, ""),
                      const SizedBox(height: 12),
                      _buildFieldItem("កាលបរិច្ឆេទ", dateVal, ""),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Icon (Link)
                const Icon(Icons.link, color: Color(0xffA88400), size: 18),
                // Right Actions
                if (request.status == "Rejected")
                  // Approved Button for Pending reviews (mapped to Rejected in dummy data)
                  InkWell(
                    onTap: () {
                      if (Get.isRegistered<ListViewController>()) {
                        // Approve the request reactively
                        (Get.find<ListViewController>() as dynamic).approveRequest(request);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffA88400),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "អនុម័ត",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Standard Icons for others
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (request.status == "Pending") ...[
                        InkWell(
                          onTap: () {
                             if (Get.isRegistered<ListViewController>()) {
                               (Get.find<ListViewController>() as dynamic).checkInRequest(
                                 request,
                               );
                             }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.login,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      InkWell(
                        onTap: () {
                          // Try to prefill the controller
                          if (Get.isRegistered<RequestViewController>()) {
                            Get.find<RequestViewController>().startEditing(
                              request,
                            );
                          }
                          if (Get.isRegistered<MainController>()) {
                            Get.find<MainController>().currentIndex.value = 1;
                          } else {
                            Get.toNamed(AppRoutes.request, arguments: request);
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                           if (Get.isRegistered<ListViewController>()) {
                             (Get.find<ListViewController>() as dynamic).deleteRequest(
                               request,
                             );
                           }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(String label, String value, String subtext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1F2937),
          ),
        ),
        if (subtext.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            subtext,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
          ),
        ],
      ],
    );
  }
}
