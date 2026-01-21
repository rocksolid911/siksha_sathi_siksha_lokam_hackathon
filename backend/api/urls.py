"""
Shiksha Saathi - API URLs
"""
from django.urls import path
from . import views
from . import auth_views

app_name = 'api'

urlpatterns = [
    # Health check
    path('health/', views.HealthCheckView.as_view(), name='health'),
    
    # ═══════════════════════════════════════════════════════════════════════════
    # AUTHENTICATION
    # ═══════════════════════════════════════════════════════════════════════════
    path('auth/sync/', auth_views.UserProfileSyncView.as_view(), name='auth-sync'),
    path('auth/profile/<str:firebase_uid>/', auth_views.UserProfileView.as_view(), name='auth-profile'),
    path('auth/fcm-token/', auth_views.UpdateFCMTokenView.as_view(), name='auth-fcm-token'),
    
    # ═══════════════════════════════════════════════════════════════════════════
    # SOS - Main feature (returns strategies + videos)
    # ═══════════════════════════════════════════════════════════════════════════
    path('sos/', views.SOSView.as_view(), name='sos'),
    
    # Strategy feedback
    path('feedback/', views.FeedbackView.as_view(), name='feedback'),
    
    # Browse strategies (for library)
    path('strategies/', views.StrategyListView.as_view(), name='strategy-list'),
    path('strategies/<int:pk>/', views.StrategyDetailView.as_view(), name='strategy-detail'),
    
    # Resources (quick tips)
    path('resources/', views.ResourcesView.as_view(), name='resources'),
    
    # NCF stats
    path('ncf-stats/', views.NCFStatsView.as_view(), name='ncf-stats'),
    
    # YouTube search
    path('youtube-search/', views.YouTubeSearchView.as_view(), name='youtube-search'),
    
    # Unified Search
    path('search/', views.GeneralSearchView.as_view(), name='general-search'),

    # Saved Resources
    path('saved-resources/', views.SavedResourceView.as_view(), name='saved-resources'),

    # Snap & Solve
    path('snap/solve/', views.SnapSolveView.as_view(), name='snap-solve'),

    # Admin - PDF indexing
    path('admin/index-pdf/', views.IndexPDFView.as_view(), name='index-pdf'),
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Social / Community Features
    # ═══════════════════════════════════════════════════════════════════════════
    path('feed/', views.SharedStrategyFeedView.as_view(), name='shared-feed'),
    path('strategies/<int:pk>/<str:action>/', views.StrategyInteractionView.as_view(), name='strategy-interaction'),
    path('trending/', views.TrendingStrategiesView.as_view(), name='trending'),
]

