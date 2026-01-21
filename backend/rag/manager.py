"""
Shiksha Saathi - RAG Manager
Enhanced RAG system with SentenceTransformer embeddings, ChromaDB, and YouTube integration.
Migrated from Flask implementation.
"""

import os
import json
import time
import logging
from pathlib import Path
from typing import List, Dict, Optional, Any

import httpx
import google.generativeai as genai
from sentence_transformers import SentenceTransformer
from pypdf import PdfReader
import chromadb
from chromadb.config import Settings
from django.conf import settings
from duckduckgo_search import DDGS

logger = logging.getLogger(__name__)


class RAGManager:
    """
    Manages Retrieval-Augmented Generation operations including document indexing,
    knowledge retrieval using vector embeddings, and YouTube video recommendations.
    """
    
    def __init__(
        self, 
        persist_directory: str = None,
        collection_name: str = "ncf_documents",
        embedding_model_name: str = 'all-MiniLM-L6-v2',
        gemini_api_key: Optional[str] = None
    ):
        """
        Initialize the RAG Manager.
        
        Args:
            persist_directory: Directory to persist vector database
            collection_name: Name of the ChromaDB collection
            embedding_model_name: Name of the sentence-transformers model
            gemini_api_key: API key for Google Gemini (optional)
        """
        self.persist_directory = persist_directory or getattr(settings, 'CHROMA_PERSIST_DIRECTORY', './chroma_db')
        self.collection_name = collection_name
        self.gemini_api_key = gemini_api_key or getattr(settings, 'GEMINI_API_KEY', '')
        
        logger.info(f"Initializing RAG Manager with collection: {collection_name}")
        
        # Initialize Gemini if key provided
        if self.gemini_api_key and self.gemini_api_key != 'your-gemini-api-key-here':
            genai.configure(api_key=self.gemini_api_key)
            logger.info("Gemini API initialized in RAG Manager")
        
        # Ensure persist directory exists
        Path(self.persist_directory).mkdir(parents=True, exist_ok=True)
        
        # Initialize embedding model (SentenceTransformer for better multilingual support)
        logger.info(f"Loading embedding model: {embedding_model_name}...")
        self.embedding_model = SentenceTransformer(embedding_model_name)
        
        # Initialize ChromaDB with persistence
        self.chroma_client = chromadb.PersistentClient(
            path=self.persist_directory,
            settings=Settings(anonymized_telemetry=False)
        )
        
        # Get or create collection
        try:
            self.collection = self.chroma_client.get_collection(name=collection_name)
            logger.info(f"Loaded existing collection: {collection_name} with {self.collection.count()} documents")
        except Exception:
            self.collection = self.chroma_client.create_collection(name=collection_name)
            logger.info(f"Created new collection: {collection_name}")
    
    def _extract_text_from_pdf(self, pdf_path: str) -> List[Dict]:
        """
        Extract text from PDF with page numbers.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            List of dictionaries with page_number and text
        """
        reader = PdfReader(pdf_path)
        pages_text = []
        
        for page_num, page in enumerate(reader.pages):
            text = page.extract_text()
            if text and text.strip():
                pages_text.append({
                    'page_number': page_num + 1,
                    'text': text
                })
        
        logger.info(f"Extracted text from {len(pages_text)} pages")
        return pages_text
    
    def _chunk_text(
        self, 
        text: str, 
        chunk_size: int = 500, 
        overlap: int = 50
    ) -> List[str]:
        """
        Split text into overlapping chunks.
        
        Args:
            text: Text to chunk
            chunk_size: Number of words per chunk
            overlap: Number of overlapping words between chunks
            
        Returns:
            List of text chunks
        """
        words = text.split()
        chunks = []
        
        for i in range(0, len(words), chunk_size - overlap):
            chunk = ' '.join(words[i:i + chunk_size])
            if len(chunk.strip()) > 0:
                chunks.append(chunk)
        
        return chunks
    
    def index_pdf(
        self, 
        pdf_path: str, 
        source_name: str = "NCF Document",
        force_reindex: bool = False
    ) -> Dict:
        """
        Index a PDF document into the vector database.
        
        Args:
            pdf_path: Path to the PDF file
            source_name: Name to identify the document source
            force_reindex: If True, re-index even if collection has documents
            
        Returns:
            Dictionary with indexing statistics
        """
        logger.info(f"Indexing PDF: {pdf_path}")
        
        # Check if already indexed
        if self.collection.count() > 0 and not force_reindex:
            count = self.collection.count()
            logger.info(f"Collection already has {count} documents. Skipping indexing.")
            return {
                'status': 'skipped',
                'reason': 'already_indexed',
                'document_count': count
            }
        
        # Force reindex - delete existing
        if force_reindex and self.collection.count() > 0:
            logger.info("Force reindex - deleting existing collection")
            self.chroma_client.delete_collection(self.collection_name)
            self.collection = self.chroma_client.create_collection(name=self.collection_name)
        
        # Extract text from PDF
        pages = self._extract_text_from_pdf(pdf_path)
        
        # Process and store chunks
        all_chunks = []
        all_metadatas = []
        all_ids = []
        
        chunk_id = 0
        for page_data in pages:
            page_num = page_data['page_number']
            text = page_data['text']
            
            # Skip empty pages
            if len(text.strip()) < 50:
                continue
            
            # Create chunks
            chunks = self._chunk_text(text)
            
            for chunk in chunks:
                all_chunks.append(chunk)
                all_metadatas.append({
                    'page': page_num,
                    'source': source_name
                })
                all_ids.append(f"chunk_{chunk_id}")
                chunk_id += 1
        
        if not all_chunks:
            return {
                'status': 'error',
                'reason': 'no_chunks_created',
                'document_count': 0
            }
        
        # Generate embeddings using SentenceTransformer
        logger.info(f"Generating embeddings for {len(all_chunks)} chunks...")
        embeddings = self.embedding_model.encode(all_chunks).tolist()
        
        # Add to ChromaDB
        self.collection.add(
            embeddings=embeddings,
            documents=all_chunks,
            metadatas=all_metadatas,
            ids=all_ids
        )
        
        logger.info(f"Successfully indexed {len(all_chunks)} chunks from {len(pages)} pages")
        
        return {
            'status': 'success',
            'chunks_count': len(all_chunks),
            'pages': len(pages),
            'source': source_name
        }
    
    def search(self, query: str, top_k: int = 3) -> List[Dict]:
        """
        Search the knowledge base for relevant content.
        
        Args:
            query: Search query text
            top_k: Number of top results to return
            
        Returns:
            List of dictionaries with text, page, source, and relevance_score
        """
        if self.collection.count() == 0:
            return []
        
        # Generate query embedding using SentenceTransformer
        query_embedding = self.embedding_model.encode([query])[0].tolist()
        
        # Search in ChromaDB
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k
        )
        
        # Format results
        formatted_results = []
        if results['documents'] and len(results['documents'][0]) > 0:
            for i, doc in enumerate(results['documents'][0]):
                distance = results['distances'][0][i] if results['distances'] else 1.0
                formatted_results.append({
                    'text': doc,
                    'page': results['metadatas'][0][i]['page'],
                    'source': results['metadatas'][0][i]['source'],
                    'relevance_score': 1 - distance  # Convert distance to similarity
                })
        
        return formatted_results
    
    def get_stats(self) -> Dict:
        """
        Get statistics about the indexed documents.
        
        Returns:
            Dictionary with collection statistics
        """
        count = self.collection.count()
        return {
            'collection_name': self.collection_name,
            'document_count': count,
            'is_ready': count > 0
        }
    
    def get_youtube_videos(self, query: str, limit: int = 5) -> List[Dict]:
        """
        Search for relevant YouTube videos using direct web scraping.
        Returns the top 'limit' playable videos.
        
        Args:
            query: Search query for YouTube
            limit: Maximum number of videos to return
            
        Returns:
            List of video dictionaries with id, title, thumbnail, link, channel, duration
        """
        videos = []
        
        try:
            import re
            import urllib.parse
            
            logger.info(f"🎥 Searching YouTube for: {query}")
            
            # URL encode the query
            encoded_query = urllib.parse.quote(query)
            search_url = f"https://www.youtube.com/results?search_query={encoded_query}"
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
            }
            
            response = httpx.get(search_url, headers=headers, timeout=10, follow_redirects=True)
            
            if response.status_code != 200:
                logger.warning(f"YouTube search returned status {response.status_code}")
                return videos
            
            html_content = response.text
            
            # Extract video IDs from the page using regex
            # YouTube embeds video data in the page as JSON
            video_id_pattern = r'"videoId":"([a-zA-Z0-9_-]{11})"'
            title_pattern = r'"title":\{"runs":\[\{"text":"([^"]+)"\}\]'
            
            video_ids = re.findall(video_id_pattern, html_content)
            
            # Remove duplicates while preserving order
            seen = set()
            unique_video_ids = []
            for vid in video_ids:
                if vid not in seen:
                    seen.add(vid)
                    unique_video_ids.append(vid)
            
            logger.debug(f"   Found {len(unique_video_ids)} unique video IDs")
            
            # Get video details using oEmbed API (reliable and free)
            for video_id in unique_video_ids[:limit * 2]:  # Get more to account for failures
                if len(videos) >= limit:
                    break
                    
                try:
                    oembed_url = f"https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json"
                    oembed_response = httpx.get(oembed_url, timeout=3)
                    
                    if oembed_response.status_code == 200:
                        oembed_data = oembed_response.json()
                        videos.append({
                            'id': video_id,
                            'title': oembed_data.get('title', 'Unknown'),
                            'thumbnail': f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg",
                            'link': f"https://www.youtube.com/watch?v={video_id}",
                            'channel': oembed_data.get('author_name', 'Unknown'),
                            'duration': 'Unknown'  # oEmbed doesn't provide duration
                        })
                        logger.debug(f"   ✅ Added video: {oembed_data.get('title', video_id)[:40]}...")
                    else:
                        logger.debug(f"   Skipping {video_id}: Not embeddable")
                        
                except Exception as e:
                    logger.debug(f"   Error fetching video {video_id}: {e}")
                    continue
            
            logger.info(f"✅ YouTube search found {len(videos)} embeddable videos")
            
        except Exception as e:
            logger.error(f"❌ YouTube Search Error: {type(e).__name__}: {e}")
        
        return videos
    
    def search_google_pdfs(self, query: str, limit: int = 5) -> List[Dict]:
        """
        Search Web for PDFs related to the query using DuckDuckGo.
        """
        pdfs = []
        search_query = f"{query} filetype:pdf"
        logger.info(f"🔎 ENTERING search_web_pdfs (DDG) for: {search_query}")
        
        try:
            # simple usage of DDGS().text()
            results = DDGS().text(search_query, max_results=limit)
            
            if results:
                logger.info(f"   - DDG returned {len(results)} raw results")
                for r in results:
                    # r is a dict: {'title': ..., 'href': ..., 'body': ...}
                    title = r.get('title', 'PDF Resource')
                    link = r.get('href', '')
                    snippet = r.get('body', 'PDF Document from Web')
                    
                    logger.info(f"   - Inspecting URL: {link}")
                    if link.lower().endswith('.pdf') or 'pdf' in link.lower():
                        pdfs.append({
                            'title': title,
                            'link': link,
                            'snippet': snippet,
                            'source': 'DuckDuckGo Search'
                        })
                    else:
                        logger.info(f"   - Skipped (not PDF): {link}")
            else:
                 logger.warning("   - DDG returned NO results.")

            logger.info(f"✅ Found {len(pdfs)} PDFs in manager")
            
        except Exception as e:
            logger.error(f"❌ Web Search failed: {e}")
            import traceback
            logger.error(traceback.format_exc())
            
        return pdfs
    
    def answer_question(
        self, 
        question: str, 
        teacher_name: str = "Teacher",
        grade: str = "",
        subject: str = "",
        context: str = "",
        time_left: int = 10,
        language: str = "hi"
    ) -> Dict:
        """
        Generate an answer using RAG and Gemini, including video recommendations.
        
        Args:
            question: Teacher's question
            teacher_name: Teacher's name for personalization
            grade: Grade level
            subject: Subject being taught
            context: Additional context
            time_left: Minutes left in class
            language: Response language (hi/en/hinglish)
            
        Returns:
            Dictionary with response, sources, strategies, and videos
        """
        logger.info(f"Processing question: {question[:50]}...")
        
        # Step 1: Search NCF knowledge base
        ncf_results = self.search(f"{subject} {question}", top_k=3)
        
        # Format NCF context
        ncf_context = ""
        sources_used = []
        avg_confidence = 0.0
        
        if ncf_results:
            logger.info(f"Found {len(ncf_results)} relevant sections in NCF")
            ncf_context = "NCF GUIDELINES (Use these as primary reference):\n"
            
            confidence_scores = []
            for result in ncf_results:
                if result['relevance_score'] > 0.3:  # Only use sufficiently relevant results
                    ncf_context += f"[NCF Page {result['page']}]: {result['text']}\n\n"
                    sources_used.append(f"NCF Page {result['page']}")
                    confidence_scores.append(result['relevance_score'])
            
            if not sources_used:
                ncf_context = ""  # No relevant results above threshold
            else:
                avg_confidence = sum(confidence_scores) / len(confidence_scores)
        
        # Build comprehensive prompt
        SYSTEM_PROMPT = """You are "Shiksha Saathi" - an expert AI Teacher Assistant for Indian school teachers.
Your goal is to provide IMMEDIATE, ACTIONABLE teaching strategies.

CRITICAL RULES:
1. Provide EXACTLY 3 strategies in valid JSON format
2. Each strategy: max 3-4 bullet points, each under 15 words
3. Start each step with a verb: "Draw", "Ask", "Divide", "Show"
4. Include time estimate for each strategy
5. Use materials available in Indian government schools

OUTPUT FORMAT (STRICT JSON):
{
  "strategies": [
    {
      "title": "Short catchy name",
      "title_hi": "हिंदी में नाम",
      "time_minutes": 2,
      "difficulty": "easy|medium|hard",
      "steps": ["Step 1", "Step 2", "Step 3"],
      "materials": ["item1", "item2"],
      "ncf_alignment": "Brief NCF principle"
    }
  ]
}"""

        user_prompt = f"""Teacher: {teacher_name}
Grade: {grade}
Subject: {subject}
Time Left: {time_left} minutes

Question: {question}

Additional Context: {context if context else 'None provided'}

{ncf_context if ncf_context else 'No specific NCF context available.'}

Respond with ONLY valid JSON containing 3 strategies."""

        # Step 2: Get AI response using Gemini
        video_data = []
        strategies = []
        response_text = ""
        
        try:
            if not self.gemini_api_key or self.gemini_api_key == 'your-gemini-api-key-here':
                logger.warning("⚠️ Gemini API key not configured - will use fallback strategies")
                raise ValueError("Gemini API key not configured")
            
            logger.info(f"🤖 Calling Gemini API (gemini-2.0-flash) for question: '{question[:50]}...'")
            
            model = genai.GenerativeModel(
                'gemini-2.0-flash',
                system_instruction=SYSTEM_PROMPT
            )
            
            # Retry logic for API rate limits
            max_retries = 3
            retry_delay = 2
            
            for attempt in range(max_retries + 1):
                try:
                    logger.debug(f"📤 Gemini API attempt {attempt + 1}/{max_retries + 1}")
                    response = model.generate_content(
                        user_prompt,
                        generation_config=genai.GenerationConfig(
                            max_output_tokens=1200,
                            temperature=0.7,
                            response_mime_type="application/json"
                        )
                    )
                    response_text = response.text
                    logger.info(f"✅ Gemini API response received ({len(response_text)} chars)")
                    logger.debug(f"📥 Raw response: {response_text[:200]}...")
                    break
                except Exception as e:
                    error_str = str(e)
                    if "429" in error_str or "quota" in error_str.lower() or "rate" in error_str.lower():
                        logger.warning(f"⏳ Rate limit hit (attempt {attempt + 1}). Waiting {retry_delay}s...")
                        if attempt < max_retries:
                            time.sleep(retry_delay)
                            retry_delay *= 2
                        else:
                            logger.error(f"❌ Rate limit exceeded after {max_retries + 1} attempts")
                            raise e
                    elif "404" in error_str:
                        logger.error(f"❌ Model not found error: {error_str}")
                        raise e
                    else:
                        logger.error(f"❌ Gemini API error: {type(e).__name__}: {error_str}")
                        raise e
            
            # Parse JSON response
            try:
                # Clean up response if needed
                clean_response = response_text.strip()
                if clean_response.startswith("```json"):
                    clean_response = clean_response[7:]
                if clean_response.startswith("```"):
                    clean_response = clean_response[3:]
                if clean_response.endswith("```"):
                    clean_response = clean_response[:-3]
                
                result = json.loads(clean_response)
                strategies = result.get('strategies', [])
                logger.info(f"✅ Parsed {len(strategies)} strategies from Gemini response")
                
                # Add IDs and video URLs
                for i, strategy in enumerate(strategies):
                    strategy['id'] = i + 1
                    strategy['success_count'] = 0
                    strategy['video_url'] = None
                    logger.debug(f"  📌 Strategy {i+1}: {strategy.get('title', 'Unknown')}")
                    
            except json.JSONDecodeError as e:
                logger.error(f"❌ JSON parsing failed: {e}")
                logger.error(f"   Raw response was: {response_text[:300]}...")
                strategies = []
                
        except Exception as e:
            logger.error(f"❌ Gemini API failed: {type(e).__name__}: {e}")
            logger.info("⚠️ Falling back to local strategies (no AI response)")
        
        # Step 3: Get YouTube videos
        try:
            logger.info(f"🎥 Searching for YouTube videos...")
            # Generate YouTube search query
            if self.gemini_api_key and self.gemini_api_key != 'your-gemini-api-key-here':
                search_model = genai.GenerativeModel('gemini-2.0-flash')
                search_prompt = f"Convert this teacher question into a 3-5 word YouTube search query for Indian education: '{question}'. Return ONLY the query, nothing else."
                search_response = search_model.generate_content(search_prompt)
                yt_query = search_response.text.strip()
                logger.debug(f"   YouTube query from AI: '{yt_query}'")
            else:
                yt_query = f"{subject} teaching {question[:30]}"
                logger.debug(f"   YouTube query (fallback): '{yt_query}'")
            
            video_data = self.get_youtube_videos(yt_query, limit=5)
            logger.info(f"✅ Found {len(video_data)} YouTube videos")
        except Exception as e:
            logger.error(f"❌ YouTube search failed: {e}")
            video_data = self.get_youtube_videos(f"{subject} teaching tips", limit=5)
            logger.info(f"⚠️ Using fallback YouTube search, found {len(video_data)} videos")
        
        # Determine source type
        is_ncf_based = len(sources_used) > 0
        source_type = "ncf_rag" if is_ncf_based else "general_knowledge"
        
        # Log final result summary
        logger.info(f"📊 Result Summary: strategies={len(strategies)}, videos={len(video_data)}, ncf_used={is_ncf_based}, confidence={round(avg_confidence, 2) if is_ncf_based else 0.0}")
        
        return {
            'strategies': strategies,
            'response': response_text,
            'sources': sources_used,
            'ncf_used': is_ncf_based,
            'source_type': source_type,
            'confidence_score': round(avg_confidence, 2) if is_ncf_based else 0.0,
            'num_sources': len(sources_used) if is_ncf_based else 0,
            'videos': video_data
        }


    def solve_problem(
        self,
        problem_text: str,
        grade: str = "",
        subject: str = "",
        language: str = "en"
    ) -> Dict:
        """
        Solve a problem step-by-step using Gemini.
        
        Args:
            problem_text: The text of the problem
            grade: Student grade level
            subject: Subject context
            language: Preferred language
            
        Returns:
            Dictionary with solution, explanation, and steps
        """
        logger.info(f"Solving problem: {problem_text[:50]}... (Grade: {grade}, Subject: {subject})")
        
        SYSTEM_PROMPT = """You are an expert school teacher in India.
Your goal is to solve the given problem step-by-step, clearly and simply.

OUTPUT FORMAT (STRICT JSON):
{
  "solution_markdown": "Full solution in markdown format. Use latex for math if needed.",
  "steps": [
    {"titile": "Step 1", "content": "Explanation..."},
    {"title": "Step 2", "content": "Explanation..."}
  ],
  "concpet_explanation": "Brief explanation of the underlying concept",
  "difficulty_level": "Easy|Medium|Hard",
  "detected_subject": "Math|Science|etc"
}

GUIDELINES:
1. Explanation should be student-friendly.
2. If it's a math problem, show clear calculation steps.
3. If it's a science problem, explain the concept first.
4. Use standard Indian curriculum terminology where applicable.
"""

        user_prompt = f"""Problem: {problem_text}
Student Grade: {grade}
Subject: {subject}
Language: {language}

Solve this step-by-step."""

        try:
             if not self.gemini_api_key or self.gemini_api_key == 'your-gemini-api-key-here':
                raise ValueError("Gemini API key not configured")
                
             model = genai.GenerativeModel(
                'gemini-2.0-flash',
                system_instruction=SYSTEM_PROMPT
             )
             
             response = model.generate_content(
                user_prompt,
                generation_config=genai.GenerationConfig(
                    response_mime_type="application/json",
                    temperature=0.4
                )
             )
             
             result = json.loads(response.text)
             return {
                 'success': True,
                 'data': result
             }

        except Exception as e:
            logger.error(f"❌ Problem solving failed: {e}")
            return {
                'success': False,
                'error': str(e),
                'data': {
                    'solution_markdown': f"**Error generating solution:** {str(e)}",
                    'steps': [],
                    'concept_explanation': "Service unavailable",
                    'difficulty_level': "Unknown",
                    'detected_subject': "Unknown"
                }
            }

# Singleton instance
_rag_manager_instance = None


def get_rag_manager() -> RAGManager:
    """Get singleton RAGManager instance"""
    global _rag_manager_instance
    if _rag_manager_instance is None:
        _rag_manager_instance = RAGManager()
    return _rag_manager_instance
