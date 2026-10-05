import React, { useState } from 'react';
import { Lock, MapPin, Send, CheckCircle2, AlertTriangle, ShieldAlert, FileSearch } from 'lucide-react';
import { GenericColumnDefinition } from './FieldBuilder';

export interface LeakAnalysisResult {
  isBlocked: boolean;
  reasons: string[];
}

export function analyzeContactLeakageJS(text: string): LeakAnalysisResult {
  if (!text || typeof text !== 'string') {
    return { isBlocked: false, reasons: [] };
  }
  const cleanText = text.trim();
  if (!cleanText) {
    return { isBlocked: false, reasons: [] };
  }

  const reasons: string[] = [];
  const lowerText = cleanText.toLowerCase();

  // 1. Email Detection (Standard & Obfuscated: user@gmail.com, user [at] domain [dot] com)
  const emailRegex = /[\w\.-]+@[\w\.-]+\.\w{2,}/i;
  const obfuscatedEmail = /[\w\.-]+\s*(?:@|\[at\]|\(at\))\s*[\w\.-]+\s*(?:\.|\bdot\b|\[dot\]|\(dot\))\s*\w{2,}/i;
  if (emailRegex.test(cleanText) || obfuscatedEmail.test(cleanText)) {
    reasons.push('ইমেইল ঠিকানা সনাক্ত হয়েছে (Email address detected)');
  }

  // 2. URLs / Social / Messaging Links (wa.me, t.me, fb.com, etc.)
  const socialUrlPattern = /(?:https?:\/\/|www\.|wa\.me|t\.me|fb\.com|facebook\.com|m\.me|imo\.im)\/[^\s]+/i;
  if (socialUrlPattern.test(cleanText)) {
    reasons.push('সরাসরি চ্যাট/মেসেঞ্জার লিংক সনাক্ত হয়েছে (Social/Messenger link detected)');
  }

  // 3. Bengali Digits Normalization (০-৯ -> 0-9)
  const bnToEnMap: Record<string, string> = {
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
  };
  const normalizedText = cleanText.replace(/[০-৯]/g, (m) => bnToEnMap[m] || m);

  // 3a. User Hard Rule: Block ANY cluster of MORE THAN 5 DIGITS (>5 digits)
  // Catches 611300180, 611+300/180, 611 300 180, 611-300-180, 0,1,2,3,1,3,3,4,5,1,1
  // and partial phone numbers where user omits leading 01 (e.g. 611300180 or 711223344)
  const digitClusterPattern = /(?:\d[^\w\n\r]*){5,}\d/g;
  let match;
  while ((match = digitClusterPattern.exec(normalizedText)) !== null) {
    const pureDigits = match[0].replace(/\D/g, '');
    if (pureDigits.length > 5) {
      reasons.push(
        `পাবলিক ফিল্ডে ৫ টির বেশি সংখ্যা (${pureDigits.length}টি ডিজিট) সনাক্ত হয়েছে: ${pureDigits.slice(0, 4)}***${pureDigits.slice(-2)}`
      );
      break;
    }
  }

  // 3b. Any standalone number token > 5 digits
  const standaloneNumbers = normalizedText.match(/\d+/g) || [];
  for (const num of standaloneNumbers) {
    if (num.length > 5) {
      reasons.push(
        `পাবলিক ফিল্ডে ৫ টির বেশি সংখ্যা (${num.length}টি ডিজিট) সনাক্ত হয়েছে: ${num.slice(0, 4)}***${num.slice(-2)}`
      );
      break;
    }
  }

  // 3c. Standard BD Phone Pattern (013..019 followed by 8 digits)
  const bdPhonePattern = /(?:\+?880|0)?1[3-9][\s\-\.,\/_]*\d{4}[\s\-\.,\/_]*\d{4}\b/;
  if (bdPhonePattern.test(normalizedText)) {
    reasons.push('বাংলাদেশী মোবাইল নম্বর সনাক্ত (Mobile phone number detected)');
  }

  // 4. English & Bengali Number Words (3+ number words in proximity)
  const numWords = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
    'শূন্য', 'এক', 'দুই', 'তিন', 'চার', 'পাঁচ', 'ছয়', 'সাত', 'আট', 'নয়',
    'ওয়ান', 'টু', 'থ্রি', 'ফোর', 'ফাইভ', 'সিক্স', 'সেভেন', 'এইট', 'নাইন', 'জিরো',
  ];
  const words = normalizedText.toLowerCase().match(/[\w\u0980-\u09FF]+/g) || [];
  let numWordCount = 0;
  for (const w of words) {
    if (numWords.includes(w)) numWordCount++;
  }
  if (numWordCount >= 3) {
    reasons.push('কথায় লেখা মোবাইল নম্বর সনাক্ত (Spelled-out number words)');
  }

  // 5. Contact Keywords + Nearby Digits
  const contactKeywords = [
    'whatsapp', 'imo', 'call me', 'call us', 'contact me', 'phone me', 'inbox', 'dm me',
    'ফোন', 'মোবাইল', 'যোগাযোগ', 'নাম্বার', 'নম্বর', 'কল দিন', 'কল করুন', 'ডায়াল', 'ইনবক্স',
  ];
  for (const kw of contactKeywords) {
    if (normalizedText.toLowerCase().includes(kw)) {
      const allDigits = normalizedText.match(/\d+/g) || [];
      if (allDigits.some((d) => d.length >= 5)) {
        reasons.push(`যোগাযোগের কি-ওয়ার্ড (${kw}) সহ ফোন নম্বর সনাক্ত`);
        break;
      }
    }
  }

  // 6. Specific Full Physical Address Leak (House, Flat, Holding with Road numbers together)
  const addressLeakPattern = /(?:house|holding|flat|বাসা|বাড়ি|হোল্ডিং|ফ্ল্যাট)[\s#:,]*(?:নং|নম্বর|no\.?|#)?\s*\d+[\s,]+(?:road|street|রোড)[\s#:,]*(?:নং|নম্বর|no\.?|#)?\s*\d+/i;
  if (addressLeakPattern.test(normalizedText)) {
    reasons.push('সুনির্দিষ্ট বাড়ি ও রোড নম্বর সনাক্ত (Exact physical address leak)');
  }

  const uniqueReasons = Array.from(new Set(reasons));
  return {
    isBlocked: uniqueReasons.length > 0,
    reasons: uniqueReasons,
  };
}

export function checkContactLeakageJS(text: string): boolean {
  return analyzeContactLeakageJS(text).isBlocked;
}

interface DynamicFormRendererProps {
  entityKey: string;
  entityName: string;
  columns: GenericColumnDefinition[];
  language?: 'bn' | 'en';
  countryCode?: string;
  currencySymbol?: string;
  onSubmit: (formData: {
    title: string;
    approx_location: string;
    recordValues: Record<string, any>;
    moderation_flag?: {
      is_flagged: boolean;
      flag_reasons: string[];
    };
  }) => Promise<void> | void;
}

export const DynamicFormRenderer: React.FC<DynamicFormRendererProps> = ({
  entityKey,
  entityName,
  columns,
  language = 'bn',
  countryCode = 'BD',
  currencySymbol = '৳',
  onSubmit,
}) => {
  const [title, setTitle] = useState('');
  const [approxLocation, setApproxLocation] = useState('মিরপুর ১০, ঢাকা');
  const [values, setValues] = useState<Record<string, any>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [leakageReasons, setLeakageReasons] = useState<Record<string, string[]>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submittedSuccess, setSubmittedSuccess] = useState(false);

  // Filter ONLY active columns from the 15 columns
  const activeColumns = columns.filter((col) => col.is_active);

  // Check Title for Contact Leakage
  const handleTitleChange = (val: string) => {
    setTitle(val);
    const analysis = analyzeContactLeakageJS(val);
    setLeakageReasons((prev) => ({
      ...prev,
      _title: analysis.reasons,
    }));
    if (errors._title) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next._title;
        return next;
      });
    }
  };

  // Check Approx Location for Contact Leakage
  const handleLocationChange = (val: string) => {
    setApproxLocation(val);
    const analysis = analyzeContactLeakageJS(val);
    setLeakageReasons((prev) => ({
      ...prev,
      _approx_location: analysis.reasons,
    }));
  };

  // Handle Dynamic Column Input Change
  const handleInputChange = (colKey: string, val: any, isPrivate: boolean) => {
    setValues((prev) => ({ ...prev, [colKey]: val }));

    // If PUBLIC field: Enforce Contact Leakage Prevention!
    if (!isPrivate) {
      const analysis = analyzeContactLeakageJS(String(val || ''));
      setLeakageReasons((prev) => ({
        ...prev,
        [colKey]: analysis.reasons,
      }));
    } else {
      // In private field, clear any leakage error (phone numbers are explicitly allowed)
      setLeakageReasons((prev) => {
        const next = { ...prev };
        delete next[colKey];
        return next;
      });
    }

    if (errors[colKey]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[colKey];
        return next;
      });
    }
  };

  const allActiveReasons = Object.values(leakageReasons).flat();
  const hasAnyLeakage = allActiveReasons.length > 0;

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!title.trim()) {
      newErrors._title = language === 'bn' ? 'পোস্টের শিরোনাম দেওয়া আবশ্যক' : 'Title is required';
    }

    if (hasAnyLeakage) {
      return false;
    }

    for (const col of activeColumns) {
      const val = values[col.col_key];
      const label = language === 'bn' ? col.label_bn : col.label_en;

      if (col.is_required && (val === undefined || val === null || val === '')) {
        newErrors[col.col_key] = language === 'bn' ? `${label} পূরণ করা আবশ্যক` : `${label} is required`;
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    try {
      await onSubmit({
        title,
        approx_location: approxLocation,
        recordValues: values,
        moderation_flag: {
          is_flagged: false,
          flag_reasons: [],
        },
      });
      setSubmittedSuccess(true);
      setTitle('');
      setValues({});
      setLeakageReasons({});
      setTimeout(() => setSubmittedSuccess(false), 5000);
    } catch (err: any) {
      alert(err.message || 'Submission failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 max-w-2xl mx-auto">
      <div className="flex items-center justify-between pb-4 mb-6 border-b border-slate-100">
        <div>
          <h2 className="text-xl font-bold text-slate-900">
            {language === 'bn' ? 'নতুন পোস্ট প্রকাশ করুন' : 'Create Publication'}
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Entity: <span className="font-bold text-slate-800">{entityName}</span> (১৫টি কলাম থেকে {activeColumns.length}টি সক্রিয় ফিল্ড রেন্ডার হচ্ছে)
          </p>
        </div>
        <span className="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 border border-blue-200 rounded-full">
          {countryCode} Region
        </span>
      </div>

      {/* GLOBAL LEAKAGE ALERT BANNER WITH SPECIFIC DETECTED REASONS */}
      {hasAnyLeakage && (
        <div className="mb-6 p-4 bg-rose-50 border-2 border-rose-400 rounded-2xl text-rose-900 text-xs font-medium space-y-2 animate-in fade-in">
          <div className="flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-rose-600 flex-shrink-0" />
            <span className="font-bold text-sm text-rose-950">
              নিরাপত্তা সতর্কতা: পাবলিক ফিল্ডে কন্টাক্ট ইনফরমেশন সনাক্ত হয়েছে!
            </span>
          </div>

          <div className="text-rose-800 leading-relaxed">
            প্ল্যাটফর্মের বাণিজ্যিক মডেল সুরক্ষায় পাবলিক ফিল্ডে ফোন নম্বর (কমা বা যেকোনো চিহ্ন দিয়ে বিভক্ত), ইমেইল, সরাসরি মেসেঞ্জার লিংক বা বাড়ির পূর্ণ ঠিকানা দেওয়া সম্পূর্ণ নিষিদ্ধ।
          </div>

          <div className="bg-white/80 p-3 rounded-xl border border-rose-200 space-y-1">
            <span className="font-bold text-rose-950 block text-[11px] uppercase tracking-wider">
              সনাক্ত হওয়া কারণসমূহ (Detected Reasons):
            </span>
            <ul className="list-disc list-inside space-y-0.5 text-rose-900 font-semibold">
              {allActiveReasons.map((reason, i) => (
                <li key={i}>{reason}</li>
              ))}
            </ul>
          </div>

          <div className="text-[11px] text-rose-700 flex items-center gap-1.5 pt-1">
            <FileSearch className="w-3.5 h-3.5" />
            <span>
              আপনার যোগাযোগ নম্বরটি নিচে থাকা <strong>🔒 প্রাইভেট কলামে</strong> দিন। আনলক ফি পরিশোধের পর ক্রেতা সেটি দেখতে পারবে।
            </span>
          </div>
        </div>
      )}

      {submittedSuccess && (
        <div className="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl text-sm flex items-center gap-3">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 flex-shrink-0" />
          <div>
            <div className="font-semibold">
              {language === 'bn' ? 'পোস্ট সফলভাবে তৈরি হয়েছে!' : 'Publication Created!'}
            </div>
            <div className="text-xs text-emerald-700 mt-0.5">
              {language === 'bn'
                ? 'পোস্টটি স্টাফ প্যানেলে মডারেশন রিভিউ (Pending Queue) এর জন্য প্রেরণ করা হয়েছে।'
                : 'Sent to Staff Moderation Queue for review before going live.'}
            </div>
          </div>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Core Title (Public) */}
        <div>
          <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
            {language === 'bn' ? 'পোস্টের শিরোনাম (Public Title) *' : 'Post Title *'}
          </label>
          <input
            type="text"
            required
            placeholder={
              language === 'bn' ? 'যেমন: Toyota Axio 2018 - Personal Used' : 'e.g. Toyota Axio 2018 - Personal Used'
            }
            value={title}
            onChange={(e) => handleTitleChange(e.target.value)}
            className={`w-full px-3.5 py-2.5 text-sm rounded-lg outline-none transition ${
              (leakageReasons._title || []).length > 0
                ? 'bg-rose-50 border-2 border-rose-500 text-rose-900 focus:ring-rose-500'
                : 'bg-slate-50 border border-slate-300 focus:ring-2 focus:ring-blue-500 focus:bg-white text-slate-900'
            }`}
          />
          {(leakageReasons._title || []).map((r, i) => (
            <p key={i} className="text-xs text-rose-600 font-bold mt-1.5 flex items-center gap-1">
              <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" />
              <span>{r}</span>
            </p>
          ))}
          {errors._title && !(leakageReasons._title || []).length && (
            <p className="text-xs text-rose-500 mt-1">{errors._title}</p>
          )}
        </div>

        {/* Public Approx Location */}
        <div>
          <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
            {language === 'bn' ? 'সাধারণ এলাকা (Approximate Area)' : 'Approximate Location'}
          </label>
          <input
            type="text"
            placeholder={language === 'bn' ? 'যেমন: মিরপুর ১০, ঢাকা' : 'e.g. Mirpur 10, Dhaka'}
            value={approxLocation}
            onChange={(e) => handleLocationChange(e.target.value)}
            className={`w-full px-3.5 py-2.5 text-sm rounded-lg outline-none transition ${
              (leakageReasons._approx_location || []).length > 0
                ? 'bg-rose-50 border-2 border-rose-500 text-rose-900'
                : 'bg-slate-50 border border-slate-300 focus:ring-2 focus:ring-blue-500 focus:bg-white text-slate-900'
            }`}
          />
          {(leakageReasons._approx_location || []).map((r, i) => (
            <p key={i} className="text-xs text-rose-600 font-bold mt-1.5 flex items-center gap-1">
              <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" />
              <span>{r}</span>
            </p>
          ))}
          <p className="text-[11px] text-slate-400 mt-1">
            {language === 'bn'
              ? 'এটি আনলক ফি ছাড়াও পাবলিকলি প্রদর্শিত হবে। কোনো পূর্ণ ঠিকানা (বাসা/রোড নং) এখানে দেওয়া যাবে না।'
              : 'Publicly visible approximate area without disclosing exact house.'}
          </p>
        </div>

        <div className="pt-2 pb-1 border-t border-slate-100 flex items-center justify-between">
          <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">
            {language === 'bn' ? 'সক্রিয় কলামসমূহ' : 'Active Generic Columns'}
          </span>
          <span className="text-[11px] font-mono text-slate-400">
            {activeColumns.length} Active Columns
          </span>
        </div>

        {/* LOOP THROUGH ACTIVE GENERIC COLUMNS (1 TO 15) */}
        {activeColumns.map((col) => {
          const label = language === 'bn' ? col.label_bn : col.label_en;
          const error = errors[col.col_key];
          const colReasons = leakageReasons[col.col_key] || [];
          const hasLeakage = colReasons.length > 0;

          return (
            <div key={col.col_key} className="space-y-1.5">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <label className="text-xs font-semibold text-slate-800">
                    {label}
                  </label>
                  <span className="text-[10px] font-mono text-slate-400 bg-slate-100 px-1 rounded">
                    {col.col_key}
                  </span>
                  {col.is_required && <span className="text-rose-500 font-bold">*</span>}
                </div>

                {/* CRITICAL: PRIVATE LOCK BADGE */}
                {col.is_private ? (
                  <div className="flex items-center gap-1 px-2 py-0.5 bg-amber-50 border border-amber-300 rounded text-[11px] font-semibold text-amber-800">
                    <Lock className="w-3 h-3 text-amber-600" />
                    <span>{language === 'bn' ? 'লক থাকবে (ফোন নম্বর সুরক্ষিত)' : 'Private (Protected)'}</span>
                  </div>
                ) : (
                  <span className="text-[10px] font-bold text-slate-400 uppercase bg-slate-100 px-1.5 py-0.5 rounded">
                    পাবলিক ফিল্ড
                  </span>
                )}
              </div>

              {/* INPUT BY TYPE */}
              {col.data_type === 'select' ? (
                <select
                  value={values[col.col_key] || ''}
                  onChange={(e) => handleInputChange(col.col_key, e.target.value, col.is_private)}
                  className="w-full px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:bg-white outline-none transition"
                >
                  <option value="">{language === 'bn' ? 'নির্বাচন করুন' : 'Select option'}</option>
                  {(col.options || []).map((opt) => (
                    <option key={opt} value={opt}>
                      {opt}
                    </option>
                  ))}
                </select>
              ) : col.data_type === 'currency' ? (
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-500 font-bold">
                    {currencySymbol}
                  </div>
                  <input
                    type="number"
                    value={values[col.col_key] ?? ''}
                    onChange={(e) => handleInputChange(col.col_key, e.target.value, col.is_private)}
                    placeholder={language === 'bn' ? 'টাকার পরিমাণ লিখুন' : 'Enter amount'}
                    className="w-full pl-8 pr-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:bg-white outline-none transition"
                  />
                </div>
              ) : col.data_type === 'phone' ? (
                <div className="relative">
                  <input
                    type="tel"
                    value={values[col.col_key] || ''}
                    onChange={(e) => handleInputChange(col.col_key, e.target.value, col.is_private)}
                    placeholder="+88017XXXXXXXX"
                    className={`w-full px-3.5 py-2.5 text-sm rounded-lg outline-none transition font-mono ${
                      col.is_private
                        ? 'bg-amber-50/50 border border-amber-300 text-amber-950 focus:ring-2 focus:ring-amber-500'
                        : hasLeakage
                        ? 'bg-rose-50 border-2 border-rose-500 text-rose-900'
                        : 'bg-slate-50 border border-slate-300'
                    }`}
                  />
                  {col.is_private && (
                    <span className="absolute right-3 top-2.5 text-[11px] text-amber-700 font-bold flex items-center gap-1">
                      <Lock className="w-3.5 h-3.5" /> এনক্রিপ্টেড
                    </span>
                  )}
                </div>
              ) : col.data_type === 'geo_point' ? (
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={values[col.col_key] || ''}
                    onChange={(e) => handleInputChange(col.col_key, e.target.value, col.is_private)}
                    placeholder={
                      language === 'bn' ? 'হোল্ডিং, বাড়ি নং, রোড নং' : 'Exact garage / office address'
                    }
                    className="flex-1 px-3.5 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:bg-white outline-none transition"
                  />
                  <button
                    type="button"
                    onClick={() => handleInputChange(col.col_key, 'বাড়ি ১২, রোড ৪, সেক্টর ৭, উত্তরা, ঢাকা', col.is_private)}
                    className="px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-medium flex items-center gap-1 border border-slate-300 transition"
                  >
                    <MapPin className="w-3.5 h-3.5 text-blue-600" />
                    {language === 'bn' ? 'ম্যাপ পিন' : 'Pin Map'}
                  </button>
                </div>
              ) : (
                <input
                  type={col.data_type === 'number' ? 'number' : 'text'}
                  value={values[col.col_key] ?? ''}
                  onChange={(e) => handleInputChange(col.col_key, e.target.value, col.is_private)}
                  placeholder={language === 'bn' ? 'তথ্য লিখুন' : 'Enter detail'}
                  className={`w-full px-3.5 py-2.5 text-sm rounded-lg outline-none transition ${
                    hasLeakage
                      ? 'bg-rose-50 border-2 border-rose-500 text-rose-900'
                      : 'bg-slate-50 border border-slate-300 focus:ring-2 focus:ring-blue-500 focus:bg-white text-slate-900'
                  }`}
                />
              )}

              {/* INLINE SPECIFIC REASONS */}
              {colReasons.map((r, i) => (
                <p key={i} className="text-xs text-rose-600 font-bold mt-1 flex items-center gap-1">
                  <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" />
                  <span>{r}</span>
                </p>
              ))}

              {error && !hasLeakage && <p className="text-xs text-rose-500">{error}</p>}
            </div>
          );
        })}

        {/* SUBMIT BUTTON (DISABLED IF LEAKAGE DETECTED) */}
        <button
          type="submit"
          disabled={isSubmitting || hasAnyLeakage}
          className={`w-full py-3.5 font-bold text-sm rounded-xl shadow-md transition flex items-center justify-center gap-2 ${
            hasAnyLeakage
              ? 'bg-rose-100 text-rose-700 cursor-not-allowed border border-rose-300'
              : 'bg-blue-600 hover:bg-blue-700 text-white'
          }`}
        >
          {isSubmitting ? (
            'পোস্ট প্রক্রিয়া করা হচ্ছে...'
          ) : hasAnyLeakage ? (
            <>
              <ShieldAlert className="w-4 h-4 text-rose-600" />
              <span>পাবলিক ফিল্ড থেকে ফোন নম্বর / ইমেইল মুছে ফেলুন ({allActiveReasons.length}টি ত্রুটি)</span>
            </>
          ) : (
            <>
              <Send className="w-4 h-4" />
              {language === 'bn' ? 'পোস্ট সাবমিট করুন (মডারেশন কিউ)' : 'Submit Post'}
            </>
          )}
        </button>
      </form>
    </div>
  );
};
