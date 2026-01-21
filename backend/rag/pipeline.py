"""
Shiksha Saathi - RAG Pipeline
Orchestrates retrieval and generation for teaching strategies.
"""
import logging
from typing import List, Dict, Any

from .retriever import get_retriever, NCFRetriever
from .gemini_client import get_gemini_client, GeminiClient

logger = logging.getLogger(__name__)


class RAGPipeline:
    """
    Complete RAG pipeline for generating teaching strategies.
    
    Flow:
    1. Receive teacher query with context
    2. Retrieve relevant NCF documents
    3. Generate strategies using Gemini with RAG context
    4. Return formatted strategies
    
    Usage:
        pipeline = RAGPipeline()
        strategies = pipeline.generate_strategies(
            query="बच्चे भिन्न नहीं समझ रहे",
            grade="4",
            subject="गणित",
            time_left=10,
            language="hi",
        )
    """
    
    def __init__(
        self,
        retriever: NCFRetriever = None,
        gemini_client: GeminiClient = None,
    ):
        self.retriever = retriever or get_retriever()
        self.gemini_client = gemini_client or get_gemini_client()
    
    def generate_strategies(
        self,
        query: str,
        grade: str,
        subject: str,
        time_left: int = 10,
        language: str = "hi",
        top_k_docs: int = 5,
    ) -> List[Dict[str, Any]]:
        """
        Generate teaching strategies using RAG.
        
        Args:
            query: Teacher's question/problem
            grade: Grade level
            subject: Subject
            time_left: Minutes left in class
            language: Language preference (hi/en/hinglish)
            top_k_docs: Number of documents to retrieve
            
        Returns:
            List of strategy dictionaries
        """
        logger.info(f"RAG Pipeline: Processing query for Grade {grade}, {subject}")
        
        # Step 1: Retrieve relevant documents
        rag_context = ""
        rag_sources = []
        
        try:
            if self.retriever.is_indexed():
                # Build search query
                search_query = f"{grade} {subject} {query}"
                
                # Retrieve documents
                documents = self.retriever.retrieve(search_query, top_k=top_k_docs)
                
                if documents:
                    # Format context for LLM
                    rag_context = self.retriever.format_context(documents)
                    
                    # Track sources
                    rag_sources = [
                        {
                            'document': doc.get('source', 'NCF-FS 2022'),
                            'page': doc.get('page_number'),
                            'relevance_score': doc.get('score', 0),
                        }
                        for doc in documents
                    ]
                    
                    logger.info(f"Retrieved {len(documents)} relevant documents")
            else:
                logger.warning("RAG not indexed, proceeding without context")
                
        except Exception as e:
            logger.error(f"Retrieval error: {e}")
            # Continue without RAG context
        
        # Step 2: Generate strategies with Gemini
        try:
            if self.gemini_client.is_configured():
                strategies = self.gemini_client.generate_strategies(
                    query=query,
                    grade=grade,
                    subject=subject,
                    time_left=time_left,
                    language=language,
                    rag_context=rag_context,
                )
                
                logger.info(f"Generated {len(strategies)} strategies with Gemini")
                return strategies
            else:
                logger.warning("Gemini not configured, returning fallback strategies")
                return self._get_fallback_strategies(query, subject)
                
        except Exception as e:
            logger.error(f"Generation error: {e}")
            return self._get_fallback_strategies(query, subject)
    
    def _get_fallback_strategies(
        self,
        query: str,
        subject: str,
    ) -> List[Dict[str, Any]]:
        """
        Return pre-defined fallback strategies when AI is unavailable.
        These are based on common teaching scenarios.
        """
        # Detect scenario from query
        query_lower = query.lower()
        
        # Math - Fractions
        if any(word in query_lower for word in ['fraction', 'भिन्न', 'half', 'आधा']):
            return self._fraction_strategies()
        
        # Classroom management
        if any(word in query_lower for word in ['chaos', 'discipline', 'अनुशासन', 'noise']):
            return self._classroom_management_strategies()
        
        # Engagement
        if any(word in query_lower for word in ['engage', 'attention', 'ध्यान', 'bore']):
            return self._engagement_strategies()
        
        # Default general strategies
        return self._general_strategies()
    
    def _fraction_strategies(self) -> List[Dict[str, Any]]:
        """Strategies for teaching fractions"""
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
                    'Color half of each circle with chalk',
                    'Point and say: "Colored part is 1/2 of pizza"',
                ],
                'materials': ['blackboard', 'colored chalk'],
                'ncf_alignment': 'Visual representation (NCF 2023)',
                'success_count': 201,
                'video_url': None,
            },
        ]
    
    def _classroom_management_strategies(self) -> List[Dict[str, Any]]:
        """Strategies for classroom management"""
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
                    'Use frozen moment to give instructions',
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
                    'Class naturally becomes quiet to hear whispers',
                ],
                'materials': [],
                'ncf_alignment': 'Collaborative learning (NCF 2023)',
                'success_count': 145,
                'video_url': None,
            },
        ]
    
    def _engagement_strategies(self) -> List[Dict[str, Any]]:
        """Strategies for student engagement"""
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
                    'Rotate helpers every 5 minutes',
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
                    '"Ram had 4 rotis and 2 friends came..."',
                    'Ask: "How much does each person get?"',
                ],
                'materials': [],
                'ncf_alignment': 'Narrative pedagogy (NCF 2023)',
                'success_count': 356,
                'video_url': None,
            },
        ]
    
    def _general_strategies(self) -> List[Dict[str, Any]]:
        """General teaching strategies"""
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
                    'Ask questions about the object',
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


# Singleton pipeline instance
_pipeline_instance = None


def get_rag_pipeline() -> RAGPipeline:
    """Get singleton RAG pipeline instance"""
    global _pipeline_instance
    if _pipeline_instance is None:
        _pipeline_instance = RAGPipeline()
    return _pipeline_instance
