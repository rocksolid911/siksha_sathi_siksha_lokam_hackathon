"""
Shiksha Saathi - PDF Indexer for RAG
Indexes the NCF PDF document into ChromaDB for retrieval.
"""
import logging
import os
from pathlib import Path
from typing import List, Dict, Any

import fitz  # PyMuPDF
import chromadb
from chromadb.config import Settings
from django.conf import settings

logger = logging.getLogger(__name__)


class NCFIndexer:
    """
    Index NCF PDF into ChromaDB for RAG retrieval.
    
    Usage:
        indexer = NCFIndexer()
        result = indexer.index_pdf('/path/to/NCF.pdf')
    """
    
    def __init__(
        self,
        persist_directory: str = None,
        collection_name: str = "ncf_documents",
        chunk_size: int = 500,
        chunk_overlap: int = 100,
    ):
        self.persist_directory = persist_directory or settings.CHROMA_PERSIST_DIRECTORY
        self.collection_name = collection_name
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        
        # Ensure persist directory exists
        Path(self.persist_directory).mkdir(parents=True, exist_ok=True)
        
        # Initialize ChromaDB client
        self.client = chromadb.PersistentClient(
            path=self.persist_directory,
            settings=Settings(anonymized_telemetry=False),
        )
        
        logger.info(f"ChromaDB initialized at: {self.persist_directory}")
    
    def extract_text_from_pdf(self, pdf_path: str) -> List[Dict[str, Any]]:
        """
        Extract text from PDF with page metadata.
        
        Returns:
            List of dicts with 'text', 'page_number', 'source'
        """
        pdf_path = Path(pdf_path)
        if not pdf_path.exists():
            raise FileNotFoundError(f"PDF not found: {pdf_path}")
        
        documents = []
        
        try:
            doc = fitz.open(str(pdf_path))
            logger.info(f"Opened PDF: {pdf_path.name} ({len(doc)} pages)")
            
            for page_num in range(len(doc)):
                page = doc[page_num]
                text = page.get_text()
                
                if text.strip():  # Only add non-empty pages
                    documents.append({
                        'text': text,
                        'page_number': page_num + 1,
                        'source': pdf_path.name,
                    })
            
            doc.close()
            logger.info(f"Extracted text from {len(documents)} pages")
            
        except Exception as e:
            logger.error(f"Error extracting PDF: {e}")
            raise
        
        return documents
    
    def create_chunks(self, documents: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Split documents into overlapping chunks for better retrieval.
        
        Returns:
            List of chunks with metadata
        """
        chunks = []
        chunk_id = 0
        
        for doc in documents:
            text = doc['text']
            page_num = doc['page_number']
            source = doc['source']
            
            # Split text into chunks
            start = 0
            while start < len(text):
                end = start + self.chunk_size
                chunk_text = text[start:end]
                
                # Try to break at sentence boundary
                if end < len(text):
                    last_period = chunk_text.rfind('.')
                    last_newline = chunk_text.rfind('\n')
                    break_point = max(last_period, last_newline)
                    
                    if break_point > self.chunk_size * 0.5:
                        chunk_text = chunk_text[:break_point + 1]
                        end = start + break_point + 1
                
                if chunk_text.strip():
                    chunks.append({
                        'id': f"chunk_{chunk_id}",
                        'text': chunk_text.strip(),
                        'metadata': {
                            'page_number': page_num,
                            'source': source,
                            'chunk_index': chunk_id,
                        }
                    })
                    chunk_id += 1
                
                # Move start with overlap
                start = end - self.chunk_overlap
                if start < 0:
                    start = 0
                if end >= len(text):
                    break
        
        logger.info(f"Created {len(chunks)} chunks from {len(documents)} pages")
        return chunks
    
    def index_pdf(self, pdf_path: str) -> Dict[str, Any]:
        """
        Main method: Extract, chunk, and index PDF.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            Dict with indexing results
        """
        logger.info(f"Starting PDF indexing: {pdf_path}")
        
        # Delete existing collection if exists
        try:
            self.client.delete_collection(self.collection_name)
            logger.info(f"Deleted existing collection: {self.collection_name}")
        except Exception:
            pass
        
        # Create new collection
        collection = self.client.create_collection(
            name=self.collection_name,
            metadata={"description": "NCF-FS 2022 Document for Shiksha Saathi RAG"}
        )
        
        # Extract text
        documents = self.extract_text_from_pdf(pdf_path)
        
        # Create chunks
        chunks = self.create_chunks(documents)
        
        if not chunks:
            raise ValueError("No chunks created from PDF")
        
        # Add to ChromaDB (it will auto-generate embeddings)
        collection.add(
            ids=[chunk['id'] for chunk in chunks],
            documents=[chunk['text'] for chunk in chunks],
            metadatas=[chunk['metadata'] for chunk in chunks],
        )
        
        logger.info(f"Indexed {len(chunks)} chunks to ChromaDB")
        
        return {
            'success': True,
            'chunks_count': len(chunks),
            'pages_processed': len(documents),
            'collection_name': self.collection_name,
        }


# Convenience function for CLI usage
def index_ncf_pdf():
    """Index the NCF PDF - can be run from command line"""
    pdf_path = settings.NCF_PDF_PATH
    
    if not os.path.exists(pdf_path):
        print(f"Error: PDF not found at {pdf_path}")
        return
    
    indexer = NCFIndexer()
    result = indexer.index_pdf(pdf_path)
    
    print(f"✅ Indexing complete!")
    print(f"   Chunks created: {result['chunks_count']}")
    print(f"   Pages processed: {result['pages_processed']}")


if __name__ == "__main__":
    # Allow running directly: python -m rag.indexer
    import django
    django.setup()
    index_ncf_pdf()
