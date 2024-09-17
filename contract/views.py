from rest_framework.views import APIView
from rest_framework.response import Response
from web3 import Web3
from django.conf import settings
from .models import Transactions

class SmartContractInteraction(APIView):
    def post(self, request):
        transaction_id = request.data.get('transaction_id')
        amount = request.data.get('amount')

        w3 = Web3(Web3.HTTPProvider(settings.WEB3_HTTP_PROVIDER))

        tx_hash = w3.eth.send_transaction({
            'to': settings.SMART_CONTRACT_ADDRESS,
            'value': amount,
            'gas': 2000000,
            'gasPrice': w3.eth.gas_price,
            'nonce': w3.eth.get_transaction_count() + 1
        })

        transaction = Transactions.objects.get(id=transaction_id)
        transaction.amount += amount
        transaction.save()

        return Response({"message": "Payment processed", "tx_hash": tx_hash.hex(), "receipt": receipt})

class CancelTransactionView(APIView):
    def post(self, request):
        transaction_id = request.data.get('transaction_id')
        
        w3 = Web3(Web3.HTTPProvider(settings.WEB3_HTTP_PROVIDER))
        tx_hash = w3.eth.send_transaction({
            'to': settings.SMART_CONTRACT_ADDRESS,
            'value': 0,
            'function': 'cancelTransaction',
            'args': [transaction_id]
        })

        transaction = Transactions.objects.get(id=transaction_id)
        transaction.status = 'Cancelled'
        transaction.save()

        return Response({"message": "Cancellation initiated", "tx_hash": tx_hash.hex()})
