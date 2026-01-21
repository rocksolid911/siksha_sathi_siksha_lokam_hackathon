"""
Shiksha Saathi - Gemini AI Client
Wrapper for Google Gemini API with system prompts.
"""
import json
import logging
from typing import List, Dict, Any, Optional

import google.generativeai as genai
from django.conf import settings

logger = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM PROMPTS
# ═══════════════════════════════════════════════════════════════════════════════

MASTER_SYSTEM_PROMPT = """
You are "Shiksha Saathi" - an expert Indian pedagogy assistant designed specifically for government school teachers in India. Your role is to provide IMMEDIATE, ACTIONABLE teaching strategies for classroom challenges.

# CORE IDENTITY
- Expert in NCF 2023, NEP 2020, and FLN (Foundational Literacy & Numeracy) frameworks
- Trained on NCERT pedagogy guides, DIKSHA content, and DIET training materials
- Culturally aware: Use Indian classroom contexts (chapati, cricket, festivals)
- Multilingual: Respond in Hindi, English, or Hinglish based on teacher's input

# CRITICAL CONSTRAINTS
1. **BREVITY IS SACRED**: 
   - Each strategy: Maximum 3-4 bullet points
   - Each bullet: Maximum 15 words
   - No lengthy explanations - teachers are IN CLASS right now

2. **ACTIONABLE ONLY**:
   - Start with a verb: "Draw", "Ask", "Divide", "Show"
   - Include time estimate: (2 min), (5 min), (1 min)
   - No theory, no background, no justification in main response

3. **ALWAYS PROVIDE EXACTLY 3 STRATEGIES**:
   - Strategy 1: Quick fix (1-2 minutes)
   - Strategy 2: Interactive activity (5-7 minutes)
   - Strategy 3: Visual/demonstration (1-3 minutes)

4. **CONTEXT AWARENESS**:
   - Consider: Grade level, subject, language medium, class size
   - Use materials available in Indian government schools
   - Assume: Limited tech, blackboard, chalk, basic stationery

5. **CULTURAL RELEVANCE**:
   - Use Indian examples: Food (roti, dal, rice), sports (cricket), festivals (Diwali)
   - Respect multilingual classrooms
   - Consider rural/urban contexts

# OUTPUT FORMAT (STRICT JSON)
You MUST respond with valid JSON in this exact format:
{
  "strategies": [
    {
      "title": "Short catchy name",
      "title_hi": "हिंदी में नाम",
      "time_minutes": 2,
      "difficulty": "easy|medium|hard",
      "steps": [
        "Step 1: Action verb + clear instruction",
        "Step 2: Action verb + clear instruction",
        "Step 3: Expected outcome"
      ],
      "materials": ["item1", "item2"],
      "ncf_alignment": "Brief NCF/FLN principle"
    }
  ]
}

# WHAT TO AVOID
❌ Don't say: "According to constructivist theory..."
✅ Do say: "Draw 3 circles, color half"

❌ Don't say: "Research shows students learn better when..."
✅ Do say: "Ask Priya to come show on board"

❌ Don't give: Essay-length explanations
✅ Do give: 3-4 bullets, verb-first, under 15 words each

# SAFETY & ETHICS
- Never suggest corporal punishment
- No gender stereotypes
- Inclusive language (all abilities, all backgrounds)
- If question is inappropriate, politely redirect

Remember: Teachers trust you because you're FAST, PRACTICAL, and ALIGNED with official frameworks. Every second counts in a live classroom!
"""

SOS_PANIC_PROMPT = """
EMERGENCY MODE ACTIVATED - Teacher needs help RIGHT NOW in classroom!

# SITUATION
Teacher is standing in front of students, lesson is failing, clock is ticking.

# YOUR MISSION
Give 3 actionable strategies in proper JSON format.

# TEACHER CONTEXT
Grade: {grade}
Subject: {subject}
Challenge: {query}
Time Left: {time_left} minutes
Language: {language}

# RETRIEVED NCF CONTEXT
{rag_context}

# OUTPUT (STRICT JSON)
Respond with ONLY valid JSON, no markdown, no explanation:
{{
  "strategies": [
    {{
      "title": "Quick fix name",
      "title_hi": "हिंदी नाम",
      "time_minutes": 2,
      "difficulty": "easy",
      "steps": ["Step 1", "Step 2", "Step 3"],
      "materials": ["blackboard", "chalk"],
      "ncf_alignment": "NCF principle"
    }},
    {{
      "title": "Interactive activity name",
      "title_hi": "हिंदी नाम",
      "time_minutes": 5,
      "difficulty": "medium",
      "steps": ["Step 1", "Step 2", "Step 3"],
      "materials": ["item1", "item2"],
      "ncf_alignment": "NCF principle"
    }},
    {{
      "title": "Visual demo name",
      "title_hi": "हिंदी नाम",
      "time_minutes": 1,
      "difficulty": "easy",
      "steps": ["Step 1", "Step 2", "Step 3"],
      "materials": ["blackboard"],
      "ncf_alignment": "NCF principle"
    }}
  ]
}}

Now respond to teacher's emergency with JSON only!
"""


class GeminiClient:
    """
    Wrapper for Google Gemini API.
    
    Usage:
        client = GeminiClient()
        strategies = await client.generate_strategies(query, context)
    """
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key or settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL
        self.model = None
        
        self._init_client()
    
    def _init_client(self):
        """Initialize Gemini client"""
        if not self.api_key or self.api_key == 'your-gemini-api-key-here':
            logger.warning("Gemini API key not configured")
            return
        
        try:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel(
                model_name=self.model_name,
                system_instruction=MASTER_SYSTEM_PROMPT,
            )
            logger.info(f"Gemini client initialized with model: {self.model_name}")
        except Exception as e:
            logger.error(f"Gemini initialization error: {e}")
            self.model = None
    
    def is_configured(self) -> bool:
        """Check if Gemini is properly configured"""
        return self.model is not None
    
    def generate_strategies(
        self,
        query: str,
        grade: str,
        subject: str,
        time_left: int,
        language: str,
        rag_context: str = "",
    ) -> List[Dict[str, Any]]:
        """
        Generate teaching strategies using Gemini.
        
        Args:
            query: Teacher's question/problem
            grade: Grade level (e.g., "4", "कक्षा 4")
            subject: Subject (e.g., "गणित", "Math")
            time_left: Minutes left in class
            language: Response language preference
            rag_context: Retrieved NCF context
            
        Returns:
            List of strategy dictionaries
        """
        if not self.is_configured():
            raise ValueError("Gemini API not configured. Please set GEMINI_API_KEY in .env")
        
        # Format the prompt
        prompt = SOS_PANIC_PROMPT.format(
            grade=grade,
            subject=subject,
            query=query,
            time_left=time_left,
            language=language,
            rag_context=rag_context or "No specific NCF context available.",
        )
        
        try:
            # Generate response
            response = self.model.generate_content(
                prompt,
                generation_config=genai.GenerationConfig(
                    temperature=0.7,
                    max_output_tokens=1500,
                    response_mime_type="application/json",
                ),
            )
            
            # Parse JSON response
            response_text = response.text.strip()
            
            # Clean up response if needed
            if response_text.startswith("```json"):
                response_text = response_text[7:]
            if response_text.startswith("```"):
                response_text = response_text[3:]
            if response_text.endswith("```"):
                response_text = response_text[:-3]
            
            result = json.loads(response_text)
            strategies = result.get('strategies', [])
            
            # Add IDs and success counts
            for i, strategy in enumerate(strategies):
                strategy['id'] = i + 1
                strategy['success_count'] = 0
                strategy['video_url'] = None
            
            logger.info(f"Generated {len(strategies)} strategies")
            return strategies
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON parsing error: {e}")
            logger.error(f"Response was: {response.text[:500]}...")
            raise ValueError("Failed to parse Gemini response as JSON")
            
        except Exception as e:
            logger.error(f"Gemini generation error: {e}")
            raise


# Singleton client instance
_client_instance = None


def get_gemini_client() -> GeminiClient:
    """Get singleton Gemini client instance"""
    global _client_instance
    if _client_instance is None:
        _client_instance = GeminiClient()
    return _client_instance
