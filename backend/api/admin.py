from django.contrib import admin

from .models import SavedStrategy, UserProfile, TeacherStats, StrategyInteraction

@admin.register(SavedStrategy)
class SavedStrategyAdmin(admin.ModelAdmin):
    list_display = ('title', 'subject', 'grade', 'is_public', 'likes_count', 'saves_count', 'created_at')
    list_filter = ('is_public', 'subject', 'grade', 'created_at')
    search_fields = ('title', 'content', 'profile__name')

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('name', 'role', 'school', 'district')
    list_filter = ('role', 'state')
    search_fields = ('name', 'email', 'firebase_uid')

admin.site.register(TeacherStats)
admin.site.register(StrategyInteraction)
