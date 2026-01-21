"""
Shiksha Saathi - RAG Retriever
Retrieves relevant NCF content for teacher queries.
"""
import logging
from typing import List, Dict, Any, Optional
from pathlib import Path

import chromadb
from chromadb.config import Settings
from django.conf import settings

logger = logging.getLogger(__name__)


class NCFRetriever:
    """
    Retrieve relevant NCF content using vector similarity search.
    
    Usage:
        retriever = NCFRetriever()
        results = retriever.retrieve("How to teach fractions?", top_k=5)
    """
    
    def __init__(
        self,
        persist_directory: str = None,
        collection_name: str = "ncf_documents",
    ):
        self.persist_directory = persist_directory or settings.CHROMA_PERSIST_DIRECTORY
        self.collection_name = collection_name
        self.collection = None
        
        self._init_client()
    
    def _init_client(self):
        """Initialize ChromaDB client and get collection"""
        try:
            self.client = chromadb.PersistentClient(
                path=self.persist_directory,
                settings=Settings(anonymized_telemetry=False),
            )
            
            # Try to get existing collection
            try:
                self.collection = self.client.get_collection(self.collection_name)
                logger.info(f"Loaded collection: {self.collection_name}")
            except Exception:
                logger.warning(f"Collection not found: {self.collection_name}")
                self.collection = None
                
        except Exception as e:
            logger.error(f"ChromaDB initialization error: {e}")
            self.client = None
            self.collection = None
    
    def is_indexed(self) -> bool:
        """Check if the collection exists and has documents"""
        return self.collection is not None and self.get_document_count() > 0
    
    def get_document_count(self) -> int:
        """Get number of documents in collection"""
        if self.collection is None:
            return 0
        try:
            return self.collection.count()
        except Exception:
            return 0
    
    def retrieve(
        self,
        query: str,
        top_k: int = 5,
        filter_metadata: Optional[Dict] = None,
    ) -> List[Dict[str, Any]]:
        """
        Retrieve relevant documents for a query.
        
        Args:
            query: The search query
            top_k: Number of results to return
            filter_metadata: Optional metadata filters
            
        Returns:
            List of relevant documents with metadata and scores
        """
        if not self.is_indexed():
            logger.warning("Collection not indexed, returning empty results")
            return []
        
        try:
            # Query ChromaDB
            results = self.collection.query(
                query_texts=[query],
                n_results=top_k,
                where=filter_metadata,
            )
            
            # Format results
            documents = []
            
            if results and results['documents']:
                for i, doc in enumerate(results['documents'][0]):
                    metadata = results['metadatas'][0][i] if results['metadatas'] else {}
                    distance = results['distances'][0][i] if results['distances'] else 0
                    
                    # Convert distance to similarity score (ChromaDB uses L2 distance)
                    similarity = 1 / (1 + distance)
                    
                    documents.append({
                        'text': doc,
                        'metadata': metadata,
                        'score': similarity,
                        'page_number': metadata.get('page_number'),
                        'source': metadata.get('source', 'NCF-FS 2022'),
                    })
            
            logger.info(f"Retrieved {len(documents)} documents for query: {query[:50]}...")
            return documents
            
        except Exception as e:
            logger.error(f"Retrieval error: {e}")
            return []
    
    def format_context(
        self,
        documents: List[Dict[str, Any]],
        max_tokens: int = 2000,
    ) -> str:
        """
        Format retrieved documents into a context string for the LLM.
        
        Args:
            documents: List of retrieved documents
            max_tokens: Approximate max tokens (chars / 4)
            
        Returns:
            Formatted context string
        """
        if not documents:
            return ""
        
        context_parts = []
        total_chars = 0
        max_chars = max_tokens * 4  # Rough token to char conversion
        
        for doc in documents:
            page = doc.get('page_number', '?')
            source = doc.get('source', 'NCF')
            text = doc['text']
            
            part = f"[{source}, Page {page}]\n{text}\n"
            
            if total_chars + len(part) > max_chars:
                break
                
            context_parts.append(part)
            total_chars += len(part)
        
        return "\n---\n".join(context_parts)


# Singleton retriever instance
_retriever_instance = None


def get_retriever() -> NCFRetriever:
    """Get singleton retriever instance"""
    global _retriever_instance
    if _retriever_instance is None:
        _retriever_instance = NCFRetriever()
    return _retriever_instance
