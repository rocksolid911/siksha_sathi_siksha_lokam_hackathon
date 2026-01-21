from googlesearch import search

print("Testing googlesearch...")
try:
    results = search("test filetype:pdf", num_results=5, lang="en")
    for url in results:
        print(f"Found: {url}")
except Exception as e:
    print(f"Error: {e}")
