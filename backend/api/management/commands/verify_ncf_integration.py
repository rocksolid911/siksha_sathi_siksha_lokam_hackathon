
from django.core.management.base import BaseCommand
from rag.manager import get_rag_manager
import logging

class Command(BaseCommand):
    help = 'Verify NCF Summary Integration'

    def handle(self, *args, **options):
        self.stdout.write("Verifying NCF Integration...")
        try:
            manager = get_rag_manager()
            
            # Check if NCF summary content is loaded
            if hasattr(manager, 'ncf_summary_content') and manager.ncf_summary_content:
                self.stdout.write(self.style.SUCCESS(f"SUCCESS: NCF summary loaded. Length: {len(manager.ncf_summary_content)}"))
                self.stdout.write(f"Preview: {manager.ncf_summary_content[:100]}...")
            else:
                self.stdout.write(self.style.ERROR("ERROR: NCF summary NOT loaded."))

            self.stdout.write("\nTriggering answer_question to check logs...")
            # We use a dummy key if needed, or rely on manager handling it.
            # The manager logs BEFORE checking the key for the generation part in my edit?
            # actually checking my edit:
            # It loads summary in __init__.
            # It logs prompt in answer_question BEFORE calling Gemini.
            # BUT, manager.py lines 500 checks for API key.
            # My added log is at line 492 (approx), which is BEFORE the API key check at line 500.
            # So it should log even if key is missing.
            
            manager.answer_question(
                question="How to teach fractions using play?",
                teacher_name="Test Teacher",
                grade="4",
                subject="Math",
                time_left=15
            )
            
            self.stdout.write(self.style.SUCCESS("Function execution completed. Check logs for 'FULL RAG PROMPT'."))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"An error occurred: {e}"))
