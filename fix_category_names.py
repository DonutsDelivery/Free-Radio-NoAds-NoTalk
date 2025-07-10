#!/usr/bin/env python3
"""
Script to convert category names from ALL CAPS to Title Case
"""

def to_title_case(text):
    # Special words that should stay lowercase (except at start)
    lowercase_words = {'and', 'or', 'of', 'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'with', 'by'}
    
    # Special abbreviations that should stay uppercase
    uppercase_words = {'DJ', 'UK', 'US', 'FM', 'AM', 'TV', 'CD', 'LP', 'EP', 'MP3', 'ID', 'EDM', 'R&B', 'RNB', 'EMO', 'EBM', 'IDM', 'BPM', 'USSR', 'USA'}
    
    # Split by common separators
    words = text.replace('/', ' / ').replace('-', ' - ').replace('&', ' & ').split()
    result = []
    
    for i, word in enumerate(words):
        # Remove parentheses for checking
        clean_word = word.strip('()')
        
        if clean_word.upper() in uppercase_words:
            # Keep special abbreviations uppercase
            result.append(word.replace(clean_word, clean_word.upper()))
        elif i > 0 and clean_word.lower() in lowercase_words and word not in ['/', '-', '&']:
            # Keep small words lowercase (except first word)
            result.append(word.replace(clean_word, clean_word.lower()))
        else:
            # Convert to title case
            result.append(word.replace(clean_word, clean_word.capitalize()))
    
    return ' '.join(result)

# Read the current file
with open('/home/user/Documents/Free-Radio-NoAds-NoTalk/radcapradio/contents/ui/radiodata.js', 'r') as f:
    content = f.read()

# Process the content line by line
lines = content.split('\n')
for i, line in enumerate(lines):
    # Look for category name lines
    if '"name":' in line and not line.strip().startswith('//'):
        # Extract the category name
        start = line.find('"name": "') + 9
        end = line.find('"', start)
        if start > 8 and end > start:
            old_name = line[start:end]
            # Skip emojis at the start
            if old_name.startswith(('🌙', '⚡', '🎸', '🍸', '🌍', '🎷', '🔥')):
                # Keep emoji, convert the rest
                emoji_end = 2
                while emoji_end < len(old_name) and old_name[emoji_end] == ' ':
                    emoji_end += 1
                emoji_part = old_name[:emoji_end]
                text_part = old_name[emoji_end:]
                new_name = emoji_part + to_title_case(text_part)
            else:
                new_name = to_title_case(old_name)
            
            # Replace in the line
            lines[i] = line.replace(old_name, new_name)
            if old_name != new_name:
                print(f"Changed: '{old_name}' -> '{new_name}'")

# Write back the modified content
with open('/home/user/Documents/Free-Radio-NoAds-NoTalk/radcapradio/contents/ui/radiodata.js', 'w') as f:
    f.write('\n'.join(lines))

print("Category names converted to title case!")