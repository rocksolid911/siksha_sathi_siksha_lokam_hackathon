"""
Shiksha Saathi - Main URL Configuration
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include('api.urls')),
    path('', lambda request: JsonResponse({"message": "Shiksha Saathi Backend is running", "status": "OK"})),
]
