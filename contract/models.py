from django.db import models
from django.utils import timezone

class Transactions(models.Model):
    unique_code = models.CharField(max_length=50)
    amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    date = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=10, choices=[('Pending', 'Pending'), ('Approved', 'Approved'), ('Rejected', 'Rejected')],default='Pending')
    smart_contract_address = models.CharField(max_length=42, blank=True, null=True)
    smart_contract_tx_hash = models.CharField(max_length=66, blank=True, null=True)

    objects = models.Manager()

    def __str__(self):
        return f"{self.amount} {self.date}"
