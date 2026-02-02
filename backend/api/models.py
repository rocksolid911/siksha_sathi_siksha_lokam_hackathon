from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    """
    Extended user profile linked to Django's built-in User model.
    Stores Firebase UID and teacher-specific information.
    Designed to work with Firebase Auth now, but compatible with Django Auth for future migration.
    """
    
    # Link to Django User (for future Django Auth migration)
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile',
        null=True,
        blank=True,
        help_text="Link to Django User for future migration"
    )
    
    # Firebase UID - primary identifier currently
    firebase_uid = models.CharField(
        max_length=128,
        unique=True,
        db_index=True,
        help_text="Firebase Authentication UID"
    )
    
    # Basic Info
    name = models.CharField(max_length=255)
    email = models.EmailField(blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    photo_url = models.URLField(blank=True, null=True)
    
    # Role
    ROLE_CHOICES = [
        ('teacher', 'Teacher'),
        ('admin', 'Admin'),
        ('mentor', 'Mentor'),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='teacher')
    
    # Teacher-specific fields
    school = models.CharField(max_length=255, blank=True, null=True)
    district = models.CharField(max_length=100, blank=True, null=True)
    state = models.CharField(max_length=100, blank=True, null=True)
    
    # Teaching details
    grades_taught = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Classes taught, e.g., '5,6,7' or 'Class 5-8'"
    )
    subjects_taught = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Subjects taught, e.g., 'Mathematics,Science'"
    )
    number_of_students = models.PositiveIntegerField(
        default=0,
        help_text="Total students in classes"
    )
    
    # Preferences
    preferred_language = models.CharField(
        max_length=10,
        default='hi',
        help_text="Preferred language code (hi, en, etc.)"
    )
    
    # FCM Token for push notifications
    fcm_token = models.TextField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_login_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        db_table = 'user_profiles'
        verbose_name = 'User Profile'
        verbose_name_plural = 'User Profiles'
    
    def __str__(self):
        return f"{self.name} ({self.role})"
    
    def to_dict(self):
        """Convert profile to dictionary for API responses"""
        return {
            'firebase_uid': self.firebase_uid,
            'name': self.name,
            'email': self.email,
            'phone_number': self.phone_number,
            'photo_url': self.photo_url,
            'role': self.role,
            'school': self.school,
            'district': self.district,
            'state': self.state,
            'grades_taught': self.grades_taught,
            'subjects_taught': self.subjects_taught,
            'number_of_students': self.number_of_students,
            'preferred_language': self.preferred_language,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }


class TeacherStats(models.Model):
    """
    Statistics and activity tracking for teachers.
    Useful for gamification and progress tracking.
    """
    
    profile = models.OneToOneField(
        UserProfile,
        on_delete=models.CASCADE,
        related_name='stats'
    )
    
    # Usage stats
    total_sos_requests = models.PositiveIntegerField(default=0)
    strategies_used = models.PositiveIntegerField(default=0)
    strategies_rated = models.PositiveIntegerField(default=0)
    positive_ratings = models.PositiveIntegerField(default=0)
    
    # Streaks and engagement
    current_streak_days = models.PositiveIntegerField(default=0)
    max_streak_days = models.PositiveIntegerField(default=0)
    last_active_date = models.DateField(blank=True, null=True)
    
    class Meta:
        db_table = 'teacher_stats'
        verbose_name = 'Teacher Stats'
        verbose_name_plural = 'Teacher Stats'
    
    def __str__(self):
        return f"Stats for {self.profile.name}"


class SavedStrategy(models.Model):
    """
    Strategies saved by teachers for future reference.
    """
    profile = models.ForeignKey(
        UserProfile,
        on_delete=models.CASCADE,
        related_name='saved_strategies'
    )
    
    # Strategy content 
    # We store a snapshot of the strategy content since it's AI generated
    title = models.CharField(max_length=255)
    title_hi = models.CharField(max_length=255, blank=True, null=True)
    
    # Content body (JSON or text)
    content = models.TextField(help_text="Full strategy content")
    
    # Metadata
    subject = models.CharField(max_length=100, blank=True, null=True)
    grade = models.CharField(max_length=50, blank=True, null=True)
    video_url = models.URLField(blank=True, null=True, help_text="YouTube video URL if available")
    
    group_id = models.UUIDField(null=True, blank=True, help_text="ID to group strategies from same SOS response")
    
    # Resource Type to distinguish between Strategy and Snap
    RESOURCE_TYPE_CHOICES = [
        ('strategy', 'Teaching Strategy'),
        ('snap', 'Snap Solution'),
        ('pdf', 'PDF Resource'),
    ]
    resource_type = models.CharField(
        max_length=20, 
        choices=RESOURCE_TYPE_CHOICES, 
        default='strategy',
        help_text="Type of saved resource"
    )
    
    # Social Stats
    likes_count = models.PositiveIntegerField(default=0)
    saves_count = models.PositiveIntegerField(default=0)
    is_public = models.BooleanField(default=True, help_text="Visible in shared feed")
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'saved_strategies'
        ordering = ['-created_at']
        
    def __str__(self):
        return f"{self.title} - {self.profile.name}"


class StrategyInteraction(models.Model):
    """
    Track user interactions with strategies (Like/Save).
    """
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='interactions')
    strategy = models.ForeignKey(SavedStrategy, on_delete=models.CASCADE, related_name='interactions')
    is_liked = models.BooleanField(default=False)
    is_saved = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'strategy_interactions'
        unique_together = ('user', 'strategy')

