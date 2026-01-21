"""
Authentication API Views for Shiksha Saathi
Handles user profile sync and Firebase token verification.
"""
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone

from .models import UserProfile, TeacherStats

logger = logging.getLogger(__name__)


class UserProfileSyncView(APIView):
    """
    Sync user profile from Firebase/Flutter app to backend.
    POST /api/v1/auth/sync/
    
    This endpoint receives user data after successful Firebase authentication
    and creates/updates the user profile in the Django database.
    """
    
    def post(self, request):
        """Sync user profile data"""
        data = request.data
        
        # Required field
        firebase_uid = data.get('firebase_uid')
        if not firebase_uid:
            return Response(
                {'error': 'firebase_uid is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Get or create profile
            profile, created = UserProfile.objects.get_or_create(
                firebase_uid=firebase_uid,
                defaults={
                    'name': data.get('name', 'Teacher'),
                    'email': data.get('email'),
                    'phone_number': data.get('phone_number'),
                    'photo_url': data.get('photo_url'),
                    'role': data.get('role', 'teacher'),
                    'school': data.get('school'),
                    'district': data.get('district'),
                    'state': data.get('state'),
                    'preferred_language': data.get('preferred_language', 'hi'),
                }
            )
            
            if not created:
                # Update existing profile
                if data.get('name'):
                    profile.name = data['name']
                if data.get('email'):
                    profile.email = data['email']
                if data.get('phone_number'):
                    profile.phone_number = data['phone_number']
                if data.get('photo_url'):
                    profile.photo_url = data['photo_url']
                if data.get('school'):
                    profile.school = data['school']
                if data.get('district'):
                    profile.district = data['district']
                if data.get('state'):
                    profile.state = data['state']
                if data.get('preferred_language'):
                    profile.preferred_language = data['preferred_language']
                
                profile.last_login_at = timezone.now()
                profile.save()
            
            # Ensure stats exist
            TeacherStats.objects.get_or_create(profile=profile)
            
            action = 'created' if created else 'updated'
            logger.info(f"✅ User profile {action}: {profile.name} ({firebase_uid[:8]}...)")
            
            return Response({
                'success': True,
                'action': action,
                'profile': profile.to_dict(),
            })
            
        except Exception as e:
            logger.error(f"❌ Profile sync error: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class UserProfileView(APIView):
    """
    Get user profile by Firebase UID.
    GET /api/v1/auth/profile/<firebase_uid>/
    """
    
    def get(self, request, firebase_uid):
        """Get user profile"""
        try:
            profile = UserProfile.objects.get(firebase_uid=firebase_uid)
            
            # Include stats if available
            stats_data = None
            if hasattr(profile, 'stats'):
                stats = profile.stats
                stats_data = {
                    'total_sos_requests': stats.total_sos_requests,
                    'strategies_used': stats.strategies_used,
                    'strategies_rated': stats.strategies_rated,
                    'positive_ratings': stats.positive_ratings,
                    'current_streak_days': stats.current_streak_days,
                    'max_streak_days': stats.max_streak_days,
                }
            
            return Response({
                'success': True,
                'profile': profile.to_dict(),
                'stats': stats_data,
            })
            
        except UserProfile.DoesNotExist:
            return Response(
                {'error': 'Profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"❌ Profile fetch error: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class UpdateFCMTokenView(APIView):
    """
    Update FCM token for push notifications.
    POST /api/v1/auth/fcm-token/
    """
    
    def post(self, request):
        """Update FCM token"""
        firebase_uid = request.data.get('firebase_uid')
        fcm_token = request.data.get('fcm_token')
        
        if not firebase_uid or not fcm_token:
            return Response(
                {'error': 'firebase_uid and fcm_token are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            profile = UserProfile.objects.get(firebase_uid=firebase_uid)
            profile.fcm_token = fcm_token
            profile.save(update_fields=['fcm_token', 'updated_at'])
            
            logger.info(f"✅ FCM token updated for: {profile.name}")
            
            return Response({
                'success': True,
                'message': 'FCM token updated',
            })
            
        except UserProfile.DoesNotExist:
            return Response(
                {'error': 'Profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"❌ FCM token update error: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
