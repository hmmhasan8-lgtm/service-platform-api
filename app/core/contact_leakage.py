"""
Advanced Contact Leakage & Suspicious Pattern Prevention Engine.
Protects the platform's Unlock Fee commercial model by detecting and blocking
any attempt to share contact numbers, emails, addresses, or messenger links
in public post fields (Title, Description, approx_location, or public custom_cols).

Supports:
- Comma-separated digits: 0,1,2,3,1,3,3,4,5,1,1
- Slash / dot / dash / underscore / pipe / emoji separated digits
- Standard Bangladesh & International phones
- Bengali digits (০-৯)
- Email addresses (both standard & obfuscated: user [at] gmail [dot] com)
- Messenger & social links (wa.me, t.me, fb.com, etc.)
- Spelled-out number words (zero, one, two, এক, দুই, তিন, ওয়ান, টু...)
- Contact keywords with numbers nearby
"""

import re
from typing import Any, Dict, List, Optional


def analyze_contact_leakage(text: Optional[str]) -> Dict[str, Any]:
    """
    Analyzes text for contact leakage or suspicious direct-contact attempts.
    Returns:
    {
        'is_blocked': bool,       # True if direct contact info detected
        'is_suspicious': bool,    # True if potential stealth pattern found
        'reasons': list[str],     # List of human-readable trigger reasons
        'detected_matches': list[str] # Matched snippets
    }
    """
    if not text or not isinstance(text, str):
        return {
            'is_blocked': False,
            'is_suspicious': False,
            'reasons': [],
            'detected_matches': [],
        }

    clean_text = text.strip()
    if not clean_text:
        return {
            'is_blocked': False,
            'is_suspicious': False,
            'reasons': [],
            'detected_matches': [],
        }

    reasons: List[str] = []
    matches: List[str] = []

    # 1. Email Detection (Standard & Obfuscated: user@gmail.com, user [at] domain [dot] com)
    email_regex = re.compile(r'[\w\.-]+@[\w\.-]+\.\w{2,}', re.IGNORECASE)
    obfuscated_email = re.compile(
        r'[\w\.-]+\s*(?:@|\[at\]|\(at\))\s*[\w\.-]+\s*(?:\.|\bdot\b|\[dot\]|\(dot\))\s*\w{2,}',
        re.IGNORECASE,
    )
    for m in email_regex.finditer(clean_text):
        reasons.append('ইমেইল ঠিকানা সনাক্ত হয়েছে (Email Address Detected)')
        matches.append(m.group(0))

    for m in obfuscated_email.finditer(clean_text):
        reasons.append('ছদ্মবেশী ইমেইল সনাক্ত হয়েছে (Obfuscated Email Detected)')
        matches.append(m.group(0))

    # 2. URLs / Messaging Links (wa.me, t.me, fb.com, etc.)
    social_url_pattern = re.compile(
        r'(?:https?:\/\/|www\.|wa\.me|t\.me|fb\.com|facebook\.com|m\.me|imo\.im)\/[^\s]+',
        re.IGNORECASE,
    )
    for m in social_url_pattern.finditer(clean_text):
        reasons.append('সরাসরি চ্যাট/মেসেঞ্জার লিংক সনাক্ত হয়েছে (Direct Messenger Link)')
        matches.append(m.group(0))

    # 3. Bengali Digits Normalization (০-৯ -> 0-9)
    bn_to_en = str.maketrans('০১২৩৪৫৬৭৮৯', '0123456789')
    normalized_text = clean_text.translate(bn_to_en)

    # 3a. User Hard Rule: Block ANY cluster of MORE THAN 5 DIGITS (>5 digits)
    # Catches 611300180, 611+300/180, 611 300 180, 611-300-180, 0,1,2,3,1,3,3,4,5,1,1
    # Catches partial phone numbers where user omits leading 01 (e.g. 611300180 or 711223344)
    digit_cluster_pattern = re.compile(r'(?:\d[^\w\n\r]*){5,}\d')
    for m in digit_cluster_pattern.finditer(normalized_text):
        matched_str = m.group(0)
        pure_digits = re.sub(r'\D', '', matched_str)
        if len(pure_digits) > 5:
            reasons.append(
                f'পাবলিক ফিল্ডে ৫ টির বেশি সংখ্যা ({len(pure_digits)}টি ডিজিট) সনাক্ত হয়েছে: {pure_digits[:4]}***{pure_digits[-2:]}'
            )
            matches.append(matched_str)
            break

    # 3b. Any standalone number token > 5 digits
    number_tokens = re.findall(r'\d+', normalized_text)
    for tok in number_tokens:
        if len(tok) > 5:
            reasons.append(
                f'পাবলিক ফিল্ডে ৫ টির বেশি সংখ্যা ({len(tok)}টি ডিজিট) সনাক্ত হয়েছে: {tok[:4]}***{tok[-2:]}'
            )
            matches.append(tok)
            break

    # 3c. Standard BD Phone Pattern (013..019 followed by 8 digits)
    bd_phone_pattern = re.compile(
        r'(?:\+?880|0)?1[3-9][\s\-\.,\/_]*\d{4}[\s\-\.,\/_]*\d{4}\b'
    )
    for m in bd_phone_pattern.finditer(normalized_text):
        reasons.append('বাংলাদেশী মোবাইল নম্বর (Bangladeshi Phone Number)')
        matches.append(m.group(0))

    # 4. English & Bengali Number Words (3+ number words in proximity)
    num_words = [
        'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
        'শূন্য', 'এক', 'দুই', 'তিন', 'চার', 'পাঁচ', 'ছয়', 'সাত', 'আট', 'নয়',
        'ওয়ান', 'টু', 'থ্রি', 'ফোর', 'ফাইভ', 'সিক্স', 'সেভেন', 'এইট', 'নাইন', 'জিরো'
    ]
    tokens = re.findall(r'[\w\u0980-\u09FF]+', normalized_text.lower())
    found_words = [t for t in tokens if t in num_words]
    if len(found_words) >= 3:
        reasons.append('কথায় লেখা মোবাইল নম্বর (Number Words Sequence)')
        matches.append(' '.join(found_words[:5]))

    # 5. Contact Keywords + Nearby Digits
    contact_keywords = [
        'whatsapp', 'imo', 'call me', 'call us', 'contact me', 'phone me', 'inbox', 'dm me',
        'ফোন', 'মোবাইল', 'যোগাযোগ', 'নাম্বার', 'নম্বর', 'কল দিন', 'কল করুন', 'ডায়াল', 'ইনবক্স'
    ]
    lower_norm = normalized_text.lower()
    for kw in contact_keywords:
        if kw in lower_norm:
            # Check for any 5+ digit sequence anywhere in the string
            all_digits = re.findall(r'\d+', normalized_text)
            if any(len(d) >= 5 for d in all_digits):
                reasons.append(f'যোগাযোগের কি-ওয়ার্ড ({kw}) সহ ফোন নম্বর সনাক্ত')
                matches.append(kw)
                break

    # 6. Specific Full Physical Address Leak (House, Flat, Holding with Road numbers together)
    address_leak_pattern = re.compile(
        r'(?:house|holding|flat|বাসা|বাড়ি|হোল্ডিং|ফ্ল্যাট)[\s#:,]*(?:নং|নম্বর|no\.?|#)?\s*\d+[\s,]+(?:road|street|রোড)[\s#:,]*(?:নং|নম্বর|no\.?|#)?\s*\d+',
        re.IGNORECASE,
    )
    if address_leak_pattern.search(normalized_text):
        reasons.append('সুনির্দিষ্ট বাড়ি ও রোড নম্বর (Exact Physical Address Leak)')
        matches.append(address_leak_pattern.search(normalized_text).group(0))

    unique_reasons = list(dict.fromkeys(reasons))
    is_blocked = len(unique_reasons) > 0

    return {
        'is_blocked': is_blocked,
        'is_suspicious': is_blocked or len(matches) > 0,
        'reasons': unique_reasons,
        'detected_matches': list(set(matches)),
    }


def detect_contact_leakage(text: Optional[str]) -> bool:
    """Convenience boolean checker for fast inline validation."""
    result = analyze_contact_leakage(text)
    return result['is_blocked']
