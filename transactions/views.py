# views.py

import logging
from django.conf import settings
from rest_framework import viewsets, status
from rest_framework.response import Response
from web3 import Web3
from .utils import load_contract_abi
from .models import Transaction
from .serializers import TransactionSerializer

# Set up logging
logger = logging.getLogger(__name__)

class TransactionViewSet(viewsets.ModelViewSet):
    queryset = Transaction.objects.all()
    serializer_class = TransactionSerializer

    def post(self, request):
        if 'file1' not in request.FILES:
            return Response({"error": "File (file1) must be provided"}, status=400)
        
        image_file1 = request.FILES['file1']
        amount = self.extract_amount_from_image(image_file1)

        try:
            transaction, created = Transaction.objects.update_or_create(
                amount=amount,
                defaults={'status': 'pending'}
            )
            message = "Transaction created" if created else "Transaction updated"
        except Exception as e:
            logger.error(f"Failed to save transaction: {e}")
            return Response({"error": f"Failed to save transaction: {str(e)}"}, status=500)

        # Pay the installment to the smart contract
        if self.pay_installment(amount):
            return Response({"message": message, "amount": amount}, status=201)
        else:
            return Response({"error": "Failed to pay installment"}, status=500)

    def extract_amount_from_image(self, image_file):
        # This function extracts the amount from the image using Google Cloud Vision
        # Your implementation here...
        pass

    def pay_installment(self, amount):
        w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
        contract_abi = load_contract_abi()
        contract_address = settings.SMART_CONTRACT_ADDRESS
        
        contract = w3.eth.contract(address=contract_address, abi=contract_abi)
        installment_amount = contract.functions.getInstallmentAmount().call()

        if amount != installment_amount:
            logger.error("Amount does not match the expected installment amount")
            return False

        try:
            tx_hash = contract.functions.payInstallment().transact({'from': w3.eth.accounts[0], 'value': amount})
            w3.eth.wait_for_transaction_receipt(tx_hash)
            return True
        except Exception as e:
            logger.error(f"Error paying installment: {e}")
            return False

    @action(detail=True, methods=['post'])
    def verify_payment(self, request, pk=None):
        transaction = self.get_object()
        
        if self.compare_details_with_vision(transaction):
            if self.verify_payment_on_blockchain(transaction):
                transaction.is_verified = True
                transaction.save()
                logger.info("Payment verified successfully.")
                return Response({"message": "Payment verified successfully."}, status=status.HTTP_200_OK)
            else:
                logger.warning("Blockchain verification failed.")
                return Response({"message": "Blockchain verification failed."}, status=status.HTTP_400_BAD_REQUEST)
        else:
            logger.warning("Document verification failed.")
            return Response({"message": "Document verification failed."}, status=status.HTTP_400_BAD_REQUEST)

    def verify_payment_on_blockchain(self, transaction):
        # Function to verify payment details on the blockchain
        # Your implementation here...
        pass

    def compare_details_with_vision(self, transaction):
        # Function to compare extracted details with the information in the image
        # Your implementation here...
        pass
