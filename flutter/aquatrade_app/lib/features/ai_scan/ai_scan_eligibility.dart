import '../../data/models/order_model.dart';

/// Status BE cho phép `POST /orders/{id}/start-ai`.
const aiEligibleStatuses = {
  OrderStatus.ESCROW_LOCKED,
  OrderStatus.COUNTING_AI,
  OrderStatus.AI_VERIFIED,
  OrderStatus.PENDING,
  OrderStatus.PREPARING,
};

bool isAiEligibleStatus(OrderStatus status) => aiEligibleStatuses.contains(status);

/// User là buyer hoặc seller của đơn.
/// Nếu BE list thiếu buyerId/sellerId — vẫn cho qua (đơn đã lấy từ /my hoặc /seller).
bool isOrderParticipant(OrderModel order, String userId) {
  if (userId.isEmpty) return false;
  if (order.buyerId.isEmpty && order.sellerId.isEmpty) return true;
  return order.buyerId == userId || order.sellerId == userId;
}

String proofRoleForUser(
  OrderModel order,
  String userId, {
  bool preferSeller = false,
}) {
  if (userId.isNotEmpty && order.sellerId == userId) return 'SELLER';
  if (userId.isNotEmpty && order.buyerId == userId) return 'BUYER';
  return preferSeller ? 'SELLER' : 'BUYER';
}

List<DigitalProofSummary> proofsForRole(OrderModel order, String role) {
  final list = order.proofs.where((p) => p.proofRole == role).toList()
    ..sort((a, b) {
      final byIndex = a.batchIndex.compareTo(b.batchIndex);
      if (byIndex != 0) return byIndex;
      return a.createdAt.compareTo(b.createdAt);
    });
  return list;
}

List<DigitalProofSummary> successfulProofsForRole(OrderModel order, String role) {
  return proofsForRole(order, role)
      .where((p) => p.status == 'SUCCESS')
      .toList();
}

bool hasPendingProofForRole(OrderModel order, String role) {
  return proofsForRole(order, role).any((p) => p.status == 'PENDING');
}

int sumSuccessfulCounts(OrderModel order, String role) {
  return successfulProofsForRole(order, role)
      .fold<int>(0, (sum, p) => sum + p.aiFishCount);
}

int expectedQuantity(OrderModel order) {
  if (order.aiExpectedQuantity > 0) return order.aiExpectedQuantity;
  return order.finalQuantity;
}

int remainingQuantity(OrderModel order, String role) {
  final expected = expectedQuantity(order);
  final counted = role == 'SELLER'
      ? (order.sellerAiTotalCount > 0
          ? order.sellerAiTotalCount
          : sumSuccessfulCounts(order, role))
      : (order.buyerAiTotalCount > 0
          ? order.buyerAiTotalCount
          : sumSuccessfulCounts(order, role));
  return (expected - counted).clamp(0, expected);
}

List<OrderModel> filterAiEligibleOrders({
  required List<OrderModel> orders,
  required String userId,
}) {
  return orders
      .where((o) => isAiEligibleStatus(o.status) && isOrderParticipant(o, userId))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
