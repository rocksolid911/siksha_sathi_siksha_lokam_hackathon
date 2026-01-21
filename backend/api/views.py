"""
Shiksha Saathi - API Views
Migrated with RAGManager integration for YouTube videos and SentenceTransformer embeddings.
"""
import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.conf import settings
from .serializers import (
    SOSRequestSerializer,
    SOSResponseSerializer,
    FeedbackRequestSerializer,
    FeedbackResponseSerializer,
    HealthCheckSerializer,
)

logger = logging.getLogger(__name__)


class HealthCheckView(APIView):
    """
    Health check endpoint
    GET /api/v1/health/
    """
    
    def get(self, request):
        """Return health status of the API"""
        rag_indexed = False
        documents_count = 0
        
        try:
            from rag.manager import get_rag_manager
            manager = get_rag_manager()
            stats = manager.get_stats()
            rag_indexed = stats['is_ready']
            documents_count = stats['document_count']
        except Exception as e:
            logger.warning(f"RAG check failed: {e}")
        
        gemini_configured = bool(
            settings.GEMINI_API_KEY and 
            settings.GEMINI_API_KEY != 'your-gemini-api-key-here'
        )
        
        data = {
            'status': 'healthy',
            'version': '1.0.0',
            'rag_indexed': rag_indexed,
            'documents_count': documents_count,
            'gemini_configured': gemini_configured,
        }
        
        serializer = HealthCheckSerializer(data)
        return Response(serializer.data)


class SOSView(APIView):
    """
    SOS Help endpoint - Main feature
    POST /api/v1/sos/
    
    Returns AI-generated teaching strategies with YouTube video recommendations.
    """
    
    def post(self, request):
        """Process SOS request and return teaching strategies with videos"""
        serializer = SOSRequestSerializer(data=request.data)
        
        if not serializer.is_valid():
            logger.warning(f"[INVALID] SOS request: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        query = serializer.validated_data['query']
        context = serializer.validated_data['context']
        
        logger.info(f"[SOS REQUEST RECEIVED]")
        logger.info(f"   Query: '{query[:80]}...'")
        logger.info(f"   Grade: {context['grade']} | Subject: {context['subject']} | Time: {context['time_left_minutes']}min")
        
        try:
            # Use RAGManager for AI-generated strategies with videos
            from rag.manager import get_rag_manager
            
            logger.debug("[RAG] Initializing RAG Manager...")
            manager = get_rag_manager()
            
            logger.info("[RAG] Calling answer_question...")
            result = manager.answer_question(
                question=query,
                grade=context['grade'],
                subject=context['subject'],
                time_left=context['time_left_minutes'],
                language=context.get('language', 'hi'),
            )
            
            strategies = result.get('strategies', [])
            videos = result.get('videos', [])
            
            logger.info(f"📊 RAG Result: {len(strategies)} strategies, {len(videos)} videos")
            logger.debug(f"   NCF used: {result.get('ncf_used', False)}")
            logger.debug(f"   Confidence: {result.get('confidence_score', 0.0)}")
            
            # If no strategies from AI, use fallback
            if not strategies:
                logger.warning("[NO AI] No AI strategies received - using fallback strategies")
                strategies = self._get_fallback_strategies(query, context)
                logger.info(f"📦 Fallback provided {len(strategies)} strategies")
            else:
                logger.info(f"[SUCCESS] AI strategies received successfully")
            
            response_data = {
                'success': True,
                'context_understood': {
                    'grade': context['grade'],
                    'subject': context['subject'],
                    'challenge': query[:100],
                },
                'strategies': strategies,
                'videos': videos,
                'rag_sources': result.get('sources', []),
                'ncf_used': result.get('ncf_used', False),
                'confidence_score': result.get('confidence_score', 0.0),
                'offline_available': False,
            }
            
            # Validate response structure before sending
            serializer = SOSResponseSerializer(data=response_data)
            if serializer.is_valid():
                logger.info(f"[VALID] SOS Response validated: {len(strategies)} strategies")
                return Response(serializer.data)
            else:
                logger.error(f"[ERROR] SOS Response verification failed: {serializer.errors}")
                # Fallthrough to except block or handle fallback here
                raise ValueError(f"Response validation failed: {serializer.errors}")
            
        except Exception as e:
            logger.error(f"[SOS ERROR] {type(e).__name__}: {e}")
            logger.info("[FALLBACK] Returning fallback strategies due to error")
            
            # Return fallback strategies
            fallback = self._get_fallback_strategies(query, context)
            logger.info(f"📦 Fallback provided {len(fallback)} strategies")
            
            response_data = {
                'success': True,
                'context_understood': {
                    'grade': context['grade'],
                    'subject': context['subject'],
                    'challenge': query[:100],
                },
                'strategies': fallback,
                'videos': [],
                'rag_sources': [],
                'ncf_used': False,
                'confidence_score': 0.0,
                'offline_available': True,
            }
            
            return Response(response_data)
    
    def _get_fallback_strategies(self, query: str, context: dict) -> list:
        """Return fallback strategies when AI is unavailable"""
        query_lower = query.lower()
        
        # Detect scenario from query
        if any(word in query_lower for word in ['fraction', 'भिन्न', 'half', 'आधा']):
            return self._fraction_strategies()
        elif any(word in query_lower for word in ['chaos', 'discipline', 'अनुशासन', 'noise', 'control']):
            return self._classroom_management_strategies()
        elif any(word in query_lower for word in ['engage', 'attention', 'ध्यान', 'bore', 'interest']):
            return self._engagement_strategies()
        
        return self._general_strategies()
    
    def _fraction_strategies(self) -> list:
        return [
            {
                'id': 1,
                'title': 'Roti Division Method',
                'title_hi': 'रोटी विभाजन विधि',
                'time_minutes': 2,
                'difficulty': 'easy',
                'steps': [
                    'Draw a full roti on board, label it as "1"',
                    'Divide it in half, point to each half as "1/2"',
                    'Ask: "If 2 friends share, how much does each get?"',
                ],
                'materials': ['blackboard', 'chalk'],
                'ncf_alignment': 'Concrete to abstract (NCF 2023)',
                'success_count': 156,
                'video_url': None,
            },
            {
                'id': 2,
                'title': 'Pair-Share Tiffin Count',
                'title_hi': 'जोड़ी में टिफिन गिनती',
                'time_minutes': 5,
                'difficulty': 'medium',
                'steps': [
                    'Pair students together',
                    'Ask them to count tiffin items together',
                    'One student takes half, both count their portions',
                    'Write on slate: my_items / total_items',
                ],
                'materials': ['students tiffins', 'slate'],
                'ncf_alignment': 'Peer learning (NCF 2023)',
                'success_count': 89,
                'video_url': None,
            },
            {
                'id': 3,
                'title': 'Pizza Circle Visual',
                'title_hi': 'पिज्जा वृत्त चित्र',
                'time_minutes': 1,
                'difficulty': 'easy',
                'steps': [
                    'Draw 3 pizza circles on the board',
                    'Color half of each circle',
                    'Point and say: "Colored part is 1/2 of pizza"',
                ],
                'materials': ['blackboard', 'colored chalk'],
                'ncf_alignment': 'Visual representation (NCF 2023)',
                'success_count': 201,
                'video_url': None,
            },
        ]
    
    def _classroom_management_strategies(self) -> list:
        return [
            {
                'id': 1,
                'title': 'Clap Pattern Game',
                'title_hi': 'ताली पैटर्न खेल',
                'time_minutes': 1,
                'difficulty': 'easy',
                'steps': [
                    'Start clapping a simple pattern (clap-clap-pause)',
                    'Students must follow and repeat together',
                    'Gradually slow down to bring silence',
                ],
                'materials': [],
                'ncf_alignment': 'Active engagement (NCF 2023)',
                'success_count': 324,
                'video_url': None,
            },
            {
                'id': 2,
                'title': 'Statue Challenge',
                'title_hi': 'मूर्ति चुनौती',
                'time_minutes': 2,
                'difficulty': 'easy',
                'steps': [
                    'Say "1, 2, 3... STATUE!"',
                    'Students must freeze immediately',
                    'Praise the best statues, others try again',
                ],
                'materials': [],
                'ncf_alignment': 'Game-based learning (NCF 2023)',
                'success_count': 278,
                'video_url': None,
            },
            {
                'id': 3,
                'title': 'Whisper Chain',
                'title_hi': 'फुसफुसाहट श्रृंखला',
                'time_minutes': 3,
                'difficulty': 'medium',
                'steps': [
                    'Whisper instruction to first row students',
                    'They whisper to next row (chain effect)',
                    'Last row says it aloud to verify',
                ],
                'materials': [],
                'ncf_alignment': 'Collaborative learning (NCF 2023)',
                'success_count': 145,
                'video_url': None,
            },
        ]
    
    def _engagement_strategies(self) -> list:
        return [
            {
                'id': 1,
                'title': 'Quick Stand Up',
                'title_hi': 'तुरंत खड़े हो जाओ',
                'time_minutes': 1,
                'difficulty': 'easy',
                'steps': [
                    'Ask a yes/no question about the topic',
                    '"If your answer is YES, stand up!"',
                    'Count who is standing, discuss why',
                ],
                'materials': [],
                'ncf_alignment': 'Physical movement (NCF 2023)',
                'success_count': 412,
                'video_url': None,
            },
            {
                'id': 2,
                'title': 'Board Helper',
                'title_hi': 'बोर्ड सहायक',
                'time_minutes': 3,
                'difficulty': 'easy',
                'steps': [
                    'Call one quiet student to the board',
                    'They become "teacher\'s helper"',
                    'Let them write/draw while you explain',
                ],
                'materials': ['blackboard', 'chalk'],
                'ncf_alignment': 'Student agency (NCF 2023)',
                'success_count': 289,
                'video_url': None,
            },
            {
                'id': 3,
                'title': 'Story Hook',
                'title_hi': 'कहानी का हुक',
                'time_minutes': 2,
                'difficulty': 'easy',
                'steps': [
                    'Start: "Let me tell you about Ram..."',
                    'Connect character to today\'s topic',
                    'Ask: "What would Ram do next?"',
                ],
                'materials': [],
                'ncf_alignment': 'Narrative pedagogy (NCF 2023)',
                'success_count': 356,
                'video_url': None,
            },
        ]
    
    def _general_strategies(self) -> list:
        return [
            {
                'id': 1,
                'title': 'Think-Pair-Share',
                'title_hi': 'सोचो-जोड़ी बनाओ-बताओ',
                'time_minutes': 5,
                'difficulty': 'easy',
                'steps': [
                    'Ask question, give 30 seconds to think alone',
                    'Pair with neighbor, discuss for 1 minute',
                    'Random pairs share with whole class',
                ],
                'materials': [],
                'ncf_alignment': 'Collaborative learning (NCF 2023)',
                'success_count': 523,
                'video_url': None,
            },
            {
                'id': 2,
                'title': 'Real Object Demo',
                'title_hi': 'असली वस्तु प्रदर्शन',
                'time_minutes': 3,
                'difficulty': 'easy',
                'steps': [
                    'Pick up any object in classroom',
                    'Connect it to today\'s topic',
                    'Pass it around, let students touch/see',
                ],
                'materials': ['any classroom object'],
                'ncf_alignment': 'Experiential learning (NCF 2023)',
                'success_count': 234,
                'video_url': None,
            },
            {
                'id': 3,
                'title': 'Quick Quiz Fingers',
                'title_hi': 'उंगलियों से क्विज़',
                'time_minutes': 2,
                'difficulty': 'easy',
                'steps': [
                    'Ask multiple choice question (A/B/C)',
                    '"Show 1 finger for A, 2 for B, 3 for C"',
                    'Count fingers quickly, address common errors',
                ],
                'materials': [],
                'ncf_alignment': 'Formative assessment (NCF 2023)',
                'success_count': 467,
                'video_url': None,
            },
        ]


class FeedbackView(APIView):
    """
    Strategy feedback endpoint
    POST /api/v1/feedback/
    """
    
    def post(self, request):
        """Submit feedback for a strategy"""
        serializer = FeedbackRequestSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        logger.info(f"Feedback received: Strategy {data['strategy_id']} | Worked: {data['worked']}")
        
        response_data = {
            'success': True,
            'message': 'धन्यवाद! Thank you for your feedback!',
            'community_impact': 'Your feedback helps 9.8 lakh teachers across India!',
        }
        
        response_serializer = FeedbackResponseSerializer(response_data)
        return Response(response_serializer.data)


class StrategyListView(APIView):
    """List cached strategies - GET /api/v1/strategies/"""
    
    def get(self, request):
        strategies = []
        return Response({'strategies': strategies})


class StrategyDetailView(APIView):
    """Get strategy details - GET /api/v1/strategies/<id>/"""
    
    def get(self, request, pk):
        return Response({'error': 'Strategy not found'}, status=status.HTTP_404_NOT_FOUND)


class ResourcesView(APIView):
    """
    Quick reference resources
    GET /api/v1/resources/
    """
    
    def get(self, request):
        """Provide quick reference resources for common challenges"""
        resources = {
            'classroom_management': {
                'title': 'Classroom Management Quick Tips',
                'title_hi': 'कक्षा प्रबंधन त्वरित सुझाव',
                'strategies': [
                    'Use a signal (bell, clap pattern) to get attention',
                    'Establish clear routines for transitions',
                    'Create mixed-ability groups of 4-5 students',
                    'Use non-verbal cues (hand signals) for common needs'
                ]
            },
            'differentiation': {
                'title': 'Differentiated Learning Strategies',
                'title_hi': 'विभेदित शिक्षण रणनीतियाँ',
                'strategies': [
                    'Task cards with different difficulty levels',
                    'Peer tutoring - advanced students help struggling ones',
                    'Learning stations with different activities',
                    'Extension tasks for early finishers'
                ]
            },
            'local_materials': {
                'title': 'Teaching with Local Materials',
                'title_hi': 'स्थानीय सामग्री से शिक्षण',
                'strategies': [
                    'Math: stones, sticks, seeds for counting and operations',
                    'Science: leaves, flowers, soil samples for observations',
                    'Language: local stories, community members as resources',
                    'Art: natural dyes, clay, leaves for creative activities'
                ]
            },
            'assessment': {
                'title': 'Quick Formative Assessment',
                'title_hi': 'त्वरित रचनात्मक मूल्यांकन',
                'strategies': [
                    'Thumbs up/down for understanding checks',
                    'Exit tickets - one question on scrap paper',
                    'Think-pair-share for oral assessment',
                    'Observation checklists during group work'
                ]
            }
        }
        
        return Response({'success': True, 'resources': resources})


class NCFStatsView(APIView):
    """
    Get NCF RAG statistics
    GET /api/v1/ncf-stats/
    """
    
    def get(self, request):
        """Get statistics about the indexed NCF document"""
        try:
            from rag.manager import get_rag_manager
            manager = get_rag_manager()
            stats = manager.get_stats()
            
            return Response({
                'success': True,
                'chunks_indexed': stats['document_count'],
                'is_ready': stats['is_ready'],
                'collection_name': stats['collection_name']
            })
        except Exception as e:
            return Response({'success': False, 'error': str(e)})


class IndexPDFView(APIView):
    """
    Admin endpoint to index NCF PDF
    POST /api/v1/admin/index-pdf/
    """
    
    def post(self, request):
        """Trigger PDF indexing"""
        try:
            from rag.manager import get_rag_manager
            
            force_reindex = request.data.get('force', False)
            pdf_path = request.data.get('pdf_path', settings.NCF_PDF_PATH)
            
            manager = get_rag_manager()
            result = manager.index_pdf(pdf_path, force_reindex=force_reindex)
            
            return Response({
                'success': True,
                'message': 'PDF indexed successfully',
                'chunks_created': result.get('chunks_count', 0),
                'status': result.get('status', 'unknown'),
            })
            
        except Exception as e:
            logger.error(f"Indexing error: {e}")
            return Response({
                'success': False,
                'error': str(e),
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class YouTubeSearchView(APIView):
    """
    Search YouTube for teaching videos
    GET /api/v1/youtube-search/?q=<query>&limit=5
    """
    
    def get(self, request):
        """Search for YouTube videos"""
        query = request.query_params.get('q', '')
        limit = int(request.query_params.get('limit', 5))
        
        if not query:
            return Response({'error': 'Query parameter "q" is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            from rag.manager import get_rag_manager
            manager = get_rag_manager()
            videos = manager.get_youtube_videos(query, limit=limit)
            
            return Response({
                'success': True,
                'query': query,
                'videos': videos,
                'count': len(videos)
            })
        except Exception as e:
            logger.error(f"YouTube search error: {e}")
            return Response({
                'success': False,
                'error': str(e),
                'videos': []
            })


class SavedResourceView(APIView):
    """
    Manage user's saved resources.
    GET /api/v1/saved-resources/
    POST /api/v1/saved-resources/
    """
    # permission_classes = [IsAuthenticated] # Enable in production

    def get(self, request):
        """Get all saved resources for the user"""
        try:
            # For hackathon/demo, we might look up by firebase_uid passed in headers
            # In a real DRF Auth setup, we'd use request.user
            firebase_uid = request.headers.get('X-Firebase-UID')
            
            if not firebase_uid:
                # Return empty or mock if no user identified
                return Response({'success': False, 'error': 'User not identified'}, status=401)

            from .models import UserProfile
            # Auto-create profile if not found (robustness for hackathon)
            profile, created = UserProfile.objects.get_or_create(
                firebase_uid=firebase_uid,
                defaults={'role': 'teacher', 'name': 'Teacher'}
            )

            strategies = profile.saved_strategies.all()
            from .serializers import SavedStrategySerializer
            serializer = SavedStrategySerializer(strategies, many=True)
            
            # Format to match frontend expectation
            data = []
            for item in serializer.data:
                data.append({
                    'id': item['id'],
                    'title': item['title'],
                    'title_hi': item['title_hi'],
                    'subject': item['subject'],
                    'grade': item['grade'],
                    'date': item['created_at'][:10], # Simple date string
                    'type': item.get('resource_type', 'strategy'),
                    'content': item['content'],
                    'video_url': item.get('video_url')
                })
                
            return Response({'success': True, 'data': data})
            
        except Exception as e:
            logger.error(f"Error fetching saved resources: {e}")
            return Response({'success': False, 'error': str(e)})

    def post(self, request):
        """Save a resource"""
        try:
             firebase_uid = request.headers.get('X-Firebase-UID')
             if not firebase_uid:
                 return Response({'success': False, 'error': 'User not identified'}, status=401)
                 
             from .models import UserProfile, SavedStrategy
             # Auto-create profile if not found
             profile, created = UserProfile.objects.get_or_create(
                firebase_uid=firebase_uid,
                defaults={'role': 'teacher', 'name': 'Teacher'}
             )
                 
             data = request.data
             resource_type = data.get('resource_type', 'strategy')
             
             # Prevent duplicates: Check if same title already exists for this profile
             strategy, created = SavedStrategy.objects.update_or_create(
                 profile=profile,
                 title=data.get('title'),
                 defaults={
                     'title_hi': data.get('title_hi', ''),
                     'content': data.get('content', ''),
                     'subject': data.get('subject', 'General'),
                     'grade': data.get('grade', 'All'),
                     'video_url': data.get('video_url'),
                     'resource_type': resource_type
                 }
             )
             
             # Grouping Logic:
             # Check if this strategy should be part of a group
             group_id = data.get('group_id') # Client can send group_id if saving multiple
             if not group_id and data.get('is_group_start', False):
                  import uuid
                  group_id = uuid.uuid4()
             
             if group_id:
                  strategy.group_id = group_id
                  strategy.save()

             return Response({
                 'success': True, 
                 'message': 'Resource saved successfully' if created else 'Resource updated',
                 'id': strategy.id,
                 'is_new': created,
                 'group_id': strategy.group_id # Return group_id so client can use it for next items
             })
             
        except Exception as e:
            logger.error(f"Error saving resource: {e}")
            return Response({'success': False, 'error': str(e)})

    def delete(self, request, pk=None):
        """Unsave a resource"""
        try:
             firebase_uid = request.headers.get('X-Firebase-UID')
             if not firebase_uid:
                 return Response({'success': False, 'error': 'User not identified'}, status=401)
                 
             from .models import UserProfile, SavedStrategy
             try:
                 profile = UserProfile.objects.get(firebase_uid=firebase_uid)
             except UserProfile.DoesNotExist:
                 return Response({'success': False, 'error': 'Profile not found'}, status=404)
            
             # If PK is provided in URL, delete by ID
             if pk:
                 SavedStrategy.objects.filter(profile=profile, id=pk).delete()
                 return Response({'success': True, 'message': 'Resource deleted'})
             
             # Fallback: Check query params
             resource_id = request.query_params.get('id')
             if resource_id:
                 SavedStrategy.objects.filter(profile=profile, id=resource_id).delete()
                 return Response({'success': True, 'message': 'Resource deleted'})
                 
             return Response({'success': False, 'error': 'ID required'}, status=400)
             
        except Exception as e:
            logger.error(f"Error deleting resource: {e}")
            return Response({'success': False, 'error': str(e)})


class GeneralSearchView(APIView):
    """
    Unified search entry point for Library/Search screen.
    GET /api/v1/search/?q=<query>
    """
    
    def get(self, request):
        query = request.query_params.get('q', '')
        if not query:
            return Response({'error': 'Query required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            from rag.manager import get_rag_manager
            manager = get_rag_manager()
            
            # 1. Search Documents (RAG)
            # We use top_k=5 for broader document search
            # 1. Search PDFs (Web - DuckDuckGo)
            # We use limit=5 for broader document search
            logger.info("🔎 Requesting Web PDF search from Manager...")
            pdfs = manager.search_google_pdfs(query, limit=5)
            logger.info(f"🔎 Manager returned {len(pdfs)} PDFs")
            doc_results = []
            for pdf in pdfs:
                doc_results.append({
                    'type': 'pdf',
                    'title': pdf.get('title', 'PDF Document'),
                    'subtitle': pdf.get('source', 'Web Search'),
                    'content': pdf.get('snippet', 'External PDF Resource'),
                    'link': pdf.get('link'),
                    'relevance': 1.0
                })
                
            # 2. Search Videos
            videos = manager.get_youtube_videos(query, limit=5)
            video_results = []
            for video in videos:
                video['type'] = 'video' # Add type tag
                video['videoId'] = video['id']
                video_results.append(video)
                
            return Response({
                'success': True,
                'query': query,
                'results': video_results + doc_results # Combined list
            })
            
        except Exception as e:
            logger.error(f"Search error: {e}")
            return Response({'success': False, 'error': str(e)})


class SharedStrategyFeedView(APIView):
    """
    Public feed of shared strategies.
    POST /api/v1/feed/ (optional filters)
    """
    def get(self, request):
        try:
            from .models import SavedStrategy, StrategyInteraction, UserProfile
            
            # Get current user for interaction status
            firebase_uid = request.headers.get('X-Firebase-UID')
            logger.info(f"[FEED] Requesting feed. UID: {firebase_uid}")
            
            current_user = None
            if firebase_uid:
                try:
                    current_user = UserProfile.objects.get(firebase_uid=firebase_uid)
                    logger.info(f"[FEED] User identified: {current_user.name}")
                except UserProfile.DoesNotExist:
                    logger.warning(f"[FEED] User profile not found for UID: {firebase_uid}")

            # Fetch all public strategies
            strategies = SavedStrategy.objects.filter(is_public=True).order_by('-created_at')
            logger.info(f"[FEED] Found {strategies.count()} public strategies")
            
            # Serialize
            from .serializers import SavedStrategySerializer
            serializer = SavedStrategySerializer(strategies, many=True)
            data = serializer.data
            
            # Apply grouping and interaction status
            grouped_feed = []
            processed_group_ids = set()
            
            # Get user interactions efficiently
            user_likes = set()
            user_saves = set()
            if current_user:
                interactions = StrategyInteraction.objects.filter(user=current_user)
                user_likes = {i.strategy_id for i in interactions if i.is_liked}
                user_saves = {i.strategy_id for i in interactions if i.is_saved}
                logger.info(f"[FEED] User has {len(user_likes)} likes and {len(user_saves)} saves")

            def enrich(item):
                s_id = item['id']
                item['is_liked'] = s_id in user_likes
                item['is_saved'] = s_id in user_saves
                return item

            for item in data:
                group_id = item.get('group_id')
                
                # Enrich first
                enrich(item)
                
                if group_id:
                    if group_id in processed_group_ids:
                        continue # Already added as part of a group
                    
                    # Find all items with this group_id
                    group_items = [enrich(i) for i in data if i.get('group_id') == group_id]
                    
                    # Create a group item
                    if group_items:
                        primary = group_items[0]
                        primary['strategies'] = [i.copy() for i in group_items]
                        
                        grouped_feed.append(primary)
                        processed_group_ids.add(group_id)
                else:
                    grouped_feed.append(item)
            
            return Response({'success': True, 'feed': grouped_feed})
        except Exception as e:
            logger.error(f"Feed error: {e}")
            return Response({'success': False, 'error': str(e)})


class SnapSolveView(APIView):
    """
    Solve a problem from text (OCR result).
    POST /api/v1/snap/solve/
    """
    
    def post(self, request):
        """Solve specific problem prompt"""
        try:
            text = request.data.get('text', '')
            if not text:
                return Response({'success': False, 'error': 'No text provided'}, status=400)
            
            # Context from request (user's active context)
            grade = request.data.get('grade', '')
            subject = request.data.get('subject', '')
            language = request.data.get('language', 'en')
            
            logger.info(f"📸 Snap Solve Request: {len(text)} chars | Grade: {grade} | Subject: {subject}")
            
            from rag.manager import get_rag_manager
            manager = get_rag_manager()
            
            result = manager.solve_problem(
                problem_text=text,
                grade=grade,
                subject=subject,
                language=language
            )
            
            return Response(result)
            
        except Exception as e:
            logger.error(f"Snap Solve Error: {e}")
            return Response({'success': False, 'error': str(e)}, status=500)




class StrategyInteractionView(APIView):
    """
    Handle social interactions (like, save).
    POST /api/v1/strategies/<id>/like/
    POST /api/v1/strategies/<id>/save/
    """
    def post(self, request, pk, action):
        try:
            firebase_uid = request.headers.get('X-Firebase-UID')
            if not firebase_uid:
                return Response({'success': False, 'error': 'User login required'}, status=401)
                
            from .models import SavedStrategy, UserProfile, StrategyInteraction
            
            try:
                user = UserProfile.objects.get(firebase_uid=firebase_uid)
                strategy = SavedStrategy.objects.get(pk=pk)
            except (UserProfile.DoesNotExist, SavedStrategy.DoesNotExist):
                return Response({'success': False, 'error': 'User or Strategy not found'}, status=404)
            
            # Get or create interaction
            interaction, created = StrategyInteraction.objects.get_or_create(user=user, strategy=strategy)

            if action == 'like':
                # Toggle like
                interaction.is_liked = not interaction.is_liked
                interaction.save()
                
                # Update counter (not atomic but okay for prototype)
                if interaction.is_liked:
                     strategy.likes_count += 1
                else:
                     strategy.likes_count = max(0, strategy.likes_count - 1)
                strategy.save()
                
                return Response({
                    'success': True, 
                    'likes_count': strategy.likes_count,
                    'is_liked': interaction.is_liked
                })
            
            elif action == 'save':
                # Toggle save
                interaction.is_saved = not interaction.is_saved
                interaction.save()
                
                if interaction.is_saved:
                     strategy.saves_count += 1
                else:
                     strategy.saves_count = max(0, strategy.saves_count - 1)
                strategy.save()
                
                return Response({
                    'success': True, 
                    'saves_count': strategy.saves_count,
                    'is_saved': interaction.is_saved
                })
            
            return Response({'success': False, 'error': 'Invalid action'}, status=400)
            
        except Exception as e:
            logger.error(f"Interaction error: {e}")
            return Response({'success': False, 'error': str(e)})


class TrendingStrategiesView(APIView):
    """
    Trending strategies based on likes + saves.
    GET /api/v1/trending/
    """
    def get(self, request):
        try:
            from .models import SavedStrategy
            from django.db.models import F
            
            from .serializers import SavedStrategySerializer
            
            # Simple trending algorithm: likes + saves
            # Filter first, then slice
            initial_query = SavedStrategy.objects.filter(is_public=True).annotate(
                score=F('likes_count') + F('saves_count')
            ).order_by('-score')
            
            logger.info(f"[TRENDING] Total public strategies: {initial_query.count()}")
            
            # Apply filters if present
            grade = request.query_params.get('grade')
            subject = request.query_params.get('subject')
            
            filtered_query = initial_query
            
            if grade:
                logger.info(f"[TRENDING] Filtering by grade: {grade}")
                filtered_query = filtered_query.filter(grade__contains=grade)
            if subject:
                logger.info(f"[TRENDING] Filtering by subject: {subject}")
                filtered_query = filtered_query.filter(subject__iexact=subject)

            count = filtered_query.count()
            logger.info(f"[TRENDING] Count after exact filter: {count}")

            # Fallback Logic
            if count == 0:
                logger.info("[TRENDING] No exact matches found. Attempting fallbacks.")
                
                # 1. Try matching Subject only (ignore grade)
                if subject and grade:
                     logger.info(f"[TRENDING] Fallback 1: Subject '{subject}' only")
                     filtered_query = initial_query.filter(subject__iexact=subject)
                     count = filtered_query.count()
                
                # 2. If still empty, use Global Trending (no filters)
                if count == 0:
                     logger.info("[TRENDING] Fallback 2: Global Trending (all subjects/grades)")
                     filtered_query = initial_query

            # Slice at the very end
            strategies = filtered_query[:10]
            logger.info(f"[TRENDING] Final strategies returned: {len(strategies)}")

            serializer = SavedStrategySerializer(strategies, many=True)
            return Response({'success': True, 'trending': serializer.data})
            
        except Exception as e:
            logger.error(f"Trending error: {e}")
            return Response({'success': False, 'error': str(e)})
