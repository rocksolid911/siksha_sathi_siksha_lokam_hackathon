"""
Shiksha Saathi - API Serializers
Updated with YouTube video support
"""
from rest_framework import serializers
from .models import SavedStrategy # Import model

class UserProfileSerializer(serializers.Serializer):
    """User profile for teachers"""
    firebase_uid = serializers.CharField(read_only=True)
    name = serializers.CharField(max_length=255)
    email = serializers.EmailField(required=False, allow_blank=True)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    photo_url = serializers.URLField(required=False, allow_null=True)
    role = serializers.ChoiceField(choices=['teacher', 'admin', 'mentor'], default='teacher')
    school = serializers.CharField(max_length=255, required=False, allow_blank=True)
    district = serializers.CharField(max_length=100, required=False, allow_blank=True)
    state = serializers.CharField(max_length=100, required=False, allow_blank=True)
    grades_taught = serializers.CharField(max_length=100, required=False, allow_blank=True)
    subjects_taught = serializers.CharField(max_length=255, required=False, allow_blank=True)
    number_of_students = serializers.IntegerField(min_value=0, default=0)
    preferred_language = serializers.ChoiceField(choices=['hi', 'en', 'hinglish'], default='hi')
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)


class TeacherContextSerializer(serializers.Serializer):
    """Context information about the teacher's classroom"""
    grade = serializers.CharField(max_length=20)
    subject = serializers.CharField(max_length=50)
    class_size = serializers.IntegerField(min_value=1, max_value=100, default=35)
    time_left_minutes = serializers.IntegerField(min_value=1, max_value=60, default=10)
    language = serializers.ChoiceField(choices=['hi', 'en', 'hinglish'], default='hi')


class SOSRequestSerializer(serializers.Serializer):
    """Request payload for SOS help"""
    query = serializers.CharField(max_length=500)
    context = TeacherContextSerializer()


class StrategySerializer(serializers.Serializer):
    """Teaching strategy response"""
    id = serializers.IntegerField()
    title = serializers.CharField()
    title_hi = serializers.CharField(required=False, allow_blank=True)
    time_minutes = serializers.IntegerField()
    difficulty = serializers.ChoiceField(choices=['easy', 'medium', 'hard'])
    steps = serializers.ListField(child=serializers.CharField())
    materials = serializers.ListField(child=serializers.CharField(), required=False)
    ncf_alignment = serializers.CharField(required=False, allow_blank=True)
    success_count = serializers.IntegerField(default=0)
    video_url = serializers.URLField(required=False, allow_null=True, allow_blank=True)


class YouTubeVideoSerializer(serializers.Serializer):
    """YouTube video recommendation"""
    id = serializers.CharField()
    title = serializers.CharField()
    thumbnail = serializers.URLField(required=False, allow_null=True)
    link = serializers.URLField()
    channel = serializers.CharField()
    duration = serializers.CharField(required=False)


class SOSResponseSerializer(serializers.Serializer):
    """Response payload for SOS help with videos"""
    success = serializers.BooleanField()
    context_understood = serializers.DictField()
    strategies = StrategySerializer(many=True)
    videos = YouTubeVideoSerializer(many=True, required=False)
    rag_sources = serializers.ListField(required=False)
    ncf_used = serializers.BooleanField(default=False)
    confidence_score = serializers.FloatField(default=0.0)
    offline_available = serializers.BooleanField(default=False)


class FeedbackRequestSerializer(serializers.Serializer):
    """Request payload for strategy feedback"""
    strategy_id = serializers.IntegerField()
    worked = serializers.BooleanField()
    rating = serializers.IntegerField(min_value=1, max_value=5, required=False)
    notes = serializers.CharField(max_length=500, required=False, allow_blank=True)
    context = TeacherContextSerializer(required=False)


class FeedbackResponseSerializer(serializers.Serializer):
    """Response payload for feedback submission"""
    success = serializers.BooleanField()
    message = serializers.CharField()
    community_impact = serializers.CharField(required=False)


class HealthCheckSerializer(serializers.Serializer):
    """Health check response"""
    status = serializers.CharField()
    version = serializers.CharField()
    rag_indexed = serializers.BooleanField()
    documents_count = serializers.IntegerField()
    gemini_configured = serializers.BooleanField()

class SavedStrategySerializer(serializers.ModelSerializer):
    """Serializer for saved strategies linked to model"""
    teacher_name = serializers.CharField(source='profile.name', read_only=True)
    teacher_school = serializers.CharField(source='profile.school', read_only=True)
    teacher_role = serializers.CharField(source='profile.role', read_only=True)
    
    # Active interaction state (populated by view)
    is_liked = serializers.BooleanField(default=False, read_only=True)
    is_saved = serializers.BooleanField(default=False, read_only=True)
    
    class Meta:
        model = SavedStrategy
        fields = [
            'id', 'title', 'title_hi', 'content', 'subject', 'grade', 'video_url', 
            'created_at', 'likes_count', 'saves_count', 'is_public',
            'teacher_name', 'teacher_school', 'teacher_role',
            'group_id', 'is_liked', 'is_saved', 'resource_type'
        ]
        read_only_fields = ['id', 'created_at', 'likes_count', 'saves_count', 'teacher_name', 'teacher_school', 'teacher_role', 'group_id']
