// contracts/LandTransaction.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandTransaction {
    address public owner;
    address public oracleAddress;
    
    struct Transaction {
        uint256 totalAmount;
        uint256 downPayment;
        uint256 penaltyRate;
        uint256 expirationDate;
        uint256 totalInstallments;
        uint256 installmentsPaid;
        uint256 refundPayment;
        uint256 lastInstallmentDate;
        uint256 installmentAmount;
        uint256 currentAmountPaid;
        bool isVerified;
        bool isPaymentRecorded;
        bytes32 termsHash;
        bool isAgreementSigned;
        bool isCancelled;
        uint256 cancellationFee;
    }

    mapping(uint256 => Transaction) public transactions;

    event TransactionAdded(
        uint256 indexed transactionId,
        uint256 indexed parcelId,
        uint256 totalAmount,
        uint256 downPayment,
        bytes32 termsHash,
        uint256 penaltyRate,
        uint256 expirationDate,
        uint256 totalInstallments
    );
    
    event PaymentVerified(uint256 indexed transactionId);
    event AgreementSigned(uint256 indexed transactionId);
    event PaymentRecorded(uint256 indexed transactionId, uint256 amount);
    event InstallmentPaid(uint256 indexed transactionId, uint256 installmentNumber, uint256 amount);
    event PaymentCancelled(uint256 indexed transactionId);

    constructor(address _oracleAddress) {
        owner = msg.sender;
        oracleAddress = _oracleAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only the oracle can call this function");
        _;
    }

    function addTransaction(
        uint256 _transactionId,
        uint256 _parcelId,
        uint256 _totalAmount,
        uint256 _downPayment,
        uint256 _penaltyRate,
        bytes32 _termsHash,
        uint256 _expirationDate,
        uint256 _totalInstallments
    ) public onlyOwner {
        require(transactions[_transactionId].totalAmount == 0, "Transaction already exists");
        uint256 installmentAmount = (_totalAmount - _downPayment) / _totalInstallments;
        transactions[_transactionId] = Transaction({
            totalAmount: _totalAmount,
            downPayment: _downPayment,
            penaltyRate: _penaltyRate,
            expirationDate: _expirationDate,
            totalInstallments: _totalInstallments,
            installmentsPaid: 0,
            lastInstallmentDate: 0,
            installmentAmount: installmentAmount,
            currentAmountPaid: 0,
            isVerified: false,
            isPaymentRecorded: false,
            termsHash: _termsHash,
            isAgreementSigned: false,
            isCancelled: false,
            cancellationFee: (_totalAmount * 0.1) // 10% cancellation fee
        });
        emit TransactionAdded(_transactionId, _parcelId, _totalAmount, _downPayment, _termsHash, _penaltyRate, _expirationDate, _totalInstallments);
    }

    function signAgreement(uint256 _transactionId) public onlyOwner {
        require(!transactions[_transactionId].isAgreementSigned, "Agreement already signed");
        transactions[_transactionId].isAgreementSigned = true;
        emit AgreementSigned(_transactionId);
    }

    function verifyPayment(uint256 _transactionId, uint256 _amount, bytes32 _termsHash) public onlyOracle {
        Transaction storage txn = transactions[_transactionId];
        require(txn.totalAmount > 0, "Transaction does not exist");
        require(txn.termsHash == _termsHash, "Terms mismatch");
        require(txn.isAgreementSigned, "Agreement not signed");
        require(!txn.isVerified, "Payment already verified");
        require(_amount >= txn.downPayment, "Amount less than down payment");
        txn.isVerified = true;
        emit PaymentVerified(_transactionId);
    }

    function recordPayment(uint256 _transactionId, uint256 _amount) public onlyOracle {
        Transaction storage txn = transactions[_transactionId];
        require(txn.isVerified, "Payment not verified");
        require(!txn.isPaymentRecorded, "Payment already recorded");
        require(_amount >= txn.installmentAmount, "Amount less than required installment");
        txn.currentAmountPaid += _amount;
        txn.installmentsPaid += 1;
        txn.lastInstallmentDate = block.timestamp;
        if (txn.currentAmountPaid >= txn.totalAmount) {
            txn.isPaymentRecorded = true;
        }
        emit PaymentRecorded(_transactionId, _amount);
    }

    function payInstallment(uint256 _transactionId, uint256 _amount) public onlyOwner {
        Transaction storage txn = transactions[_transactionId];
        require(txn.totalAmount > 0, "Transaction does not exist");
        require(txn.isVerified, "Payment not verified");
        require(block.timestamp <= txn.expirationDate, "Contract has expired");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount >= txn.installmentAmount, "Amount less than required installment");
        txn.currentAmountPaid += _amount;
        txn.installmentsPaid += 1;
        txn.lastInstallmentDate = block.timestamp;
        if (txn.currentAmountPaid >= txn.totalAmount) {
            txn.isPaymentRecorded = true;
        }
        emit InstallmentPaid(_transactionId, txn.installmentsPaid, _amount);
    }

    function cancelTransaction(uint256 _transactionId) public onlyOwner {
        Transaction storage txn = transactions[_transactionId];
        require(!txn.isCancelled, "Transaction is already cancelled");
        require(txn.totalAmount > 0, "Transaction does not exist");
        require(block.timestamp <= txn.expirationDate, "Contract has expired");
        payable(msg.sender).transfer(txn.cancellationFee);
        txn.isCancelled = true;
        emit PaymentCancelled(_transactionId);
    }

    function refundPayment(uint256 _transactionId, uint256 _amount) public onlyOwner {
        Transaction storage txn = transactions[_transactionId];
        require(txn.isVerified, "Payment not verified");
        require(txn.currentAmountPaid >= _amount, "Insufficient funds");
        require(!txn.isPaymentRecorded, "Payment already recorded");
        txn.currentAmountPaid -= _amount;
        emit refundPayment(_transactionId, _amount);
    }

    function getRemainingInstallments(uint256 _transactionId) public view returns (uint256) {
        require(transactions[_transactionId].totalAmount > 0, "Transaction does not exist");
        return transactions[_transactionId].totalInstallments - transactions[_transactionId].installmentsPaid;
    }

    function getPenalty(uint256 _transactionId) public view returns (uint256) {
        require(transactions[_transactionId].totalAmount > 0, "Transaction does not exist");
        uint256 penalty = (transactions[_transactionId].totalAmount * transactions[_transactionId].penaltyRate) / 100;
        return penalty;
    }
}
