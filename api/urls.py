from django.urls import path
from .views import TransactionsListView, NotificationsListView, TransactionsSearchView, TransactionsDetailView, DashboardListView

urlpatterns =[
   path("transactions/",TransactionsListView.as_view(), name="transactions_list_view"),
   path("notifications/",NotificationsListView.as_view(), name="notifications_list_view"),
   path("transactions/search/",TransactionsSearchView.as_view(),name="transactions_search_view"),
   path("transactions/<int:id>/", TransactionsDetailView.as_view(), name="transactions_detail_view"),
   path("dashboard/transactions/",DashboardListView.as_view(), name="dashboard_list_view"),
]