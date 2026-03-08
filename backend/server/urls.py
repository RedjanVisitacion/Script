"""
URL configuration for server project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
"""

from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from api.views import StudentViewSet

# Create DRF router and register viewsets
router = DefaultRouter()
router.register(r'students', StudentViewSet)

# Combine router URLs with other URL patterns
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),  # include the router URLs
]