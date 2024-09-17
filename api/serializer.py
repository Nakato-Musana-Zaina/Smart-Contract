from rest_framework import serializers
from transactions.models import Transactions
from notifications.models import Notifications

class TransactionsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transactions
        fields = '__all__'
class NotificationsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notifications
        fields = '__all__'