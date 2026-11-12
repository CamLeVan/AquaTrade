package com.aquatrade.core.domain.enums;

/**
 * Phương thức nạp tiền vào Ví hệ thống.
 * Chỉ có giá trị khi TransactionType = TOP_UP.
 *
 * VNPAY         = Cổng thanh toán VNPay (lưu kèm vnpay_reference để đối soát).
 * MOMO          = Ví điện tử MoMo.
 * BANK_TRANSFER = Chuyển khoản ngân hàng trực tiếp.
 */
public enum PaymentMethod {
    VNPAY,
    MOMO,
    BANK_TRANSFER
}
