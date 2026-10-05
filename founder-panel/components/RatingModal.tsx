'use client';

import React, { useState } from 'react';
import {
  Star,
  CheckCircle2,
  X,
  MessageSquare,
  Award,
  Sparkles,
} from 'lucide-react';

interface RatingModalProps {
  isOpen: boolean;
  onClose: () => void;
  requestId: string;
  providerName: string;
  providerId: string;
  currentLevel?: string;
  onRatingSuccess: (rating: number, review: string) => void;
}

export const RatingModal: React.FC<RatingModalProps> = ({
  isOpen,
  onClose,
  requestId,
  providerName,
  providerId,
  currentLevel = 'Gold',
  onRatingSuccess,
}) => {
  const [rating, setRating] = useState<number>(5);
  const [hoverRating, setHoverRating] = useState<number>(0);
  const [reviewText, setReviewText] = useState('খুবই দক্ষ এবং সময়মতো কাজ সম্পন্ন করেছেন। ব্যবহার অমায়িক।');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      await fetch(`/requests/${requestId}/rate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          rater_user_id: '11111111-1111-1111-1111-111111111111',
          rated_user_id: providerId,
          rating,
          review_text: reviewText,
          role: 'seeker_to_provider',
        }),
      }).catch(() => {});

      setSubmitted(true);
      setTimeout(() => {
        onRatingSuccess(rating, reviewText);
        onClose();
      }, 1200);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl p-6 sm:p-7 max-w-md w-full shadow-2xl space-y-5 animate-in fade-in zoom-in-95">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-amber-50 text-amber-500 rounded-xl">
              <Star className="w-5 h-5 fill-amber-500" />
            </div>
            <div>
              <h3 className="font-extrabold text-base text-slate-900">কাজ শেষ হয়েছে? রেটিং দিন</h3>
              <p className="text-[11px] text-slate-500">{providerName} এর কাজের মূল্যায়ন</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100">
            <X className="w-5 h-5" />
          </button>
        </div>

        {submitted ? (
          <div className="text-center py-6 space-y-2">
            <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto" />
            <h4 className="font-bold text-slate-900 text-sm">রেটিং সফলভাবে সম্পন্ন হয়েছে!</h4>
            <p className="text-xs text-slate-500">আপনার মতামত প্রোভাইডারের লেভেল বৃদ্ধিতে সহায়তা করবে।</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            <div className="text-center py-2 space-y-1">
              <span className="text-[11px] text-slate-500 font-bold uppercase tracking-wider block">
                সার্ভিস অভিজ্ঞতা রেট করুন
              </span>
              <div className="flex items-center justify-center gap-2 pt-1">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    onClick={() => setRating(star)}
                    onMouseEnter={() => setHoverRating(star)}
                    onMouseLeave={() => setHoverRating(0)}
                    className="p-1 transition-transform hover:scale-125 focus:outline-none"
                  >
                    <Star
                      className={`w-7 h-7 ${
                        star <= (hoverRating || rating)
                          ? 'text-amber-400 fill-amber-400'
                          : 'text-slate-300'
                      }`}
                    />
                  </button>
                ))}
              </div>
              <span className="font-bold text-amber-600 block text-xs">
                {rating === 5 ? 'অসাধারণ (৫/৫)' : rating === 4 ? 'খুব ভালো (৪/৫)' : rating === 3 ? 'মোটামুটি (৩/৫)' : 'উন্নতি প্রয়োজন'}
              </span>
            </div>

            <div>
              <label className="block font-bold text-slate-700 uppercase mb-1">
                মতামত / রিভিউ (Review Text)
              </label>
              <textarea
                rows={3}
                required
                value={reviewText}
                onChange={(e) => setReviewText(e.target.value)}
                placeholder="প্রোভাইডারের কাজের মান কেমন ছিল লিখুন..."
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs outline-none focus:ring-2 focus:ring-blue-500 text-slate-900 resize-none"
              />
            </div>

            <div className="p-3 bg-indigo-50 border border-indigo-200 rounded-2xl flex items-center justify-between text-[11px]">
              <div className="flex items-center gap-1.5 text-indigo-900 font-bold">
                <Award className="w-4 h-4 text-indigo-600" />
                <span>গেমিফিকেশন লেভেল সিস্টেম:</span>
              </div>
              <span className="px-2 py-0.5 rounded bg-indigo-600 text-white font-extrabold text-[10px]">
                {currentLevel} Tier
              </span>
            </div>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
              >
                বাতিল
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-bold rounded-xl shadow-sm transition"
              >
                {isSubmitting ? 'জমা হচ্ছে...' : 'রেটিং সাবমিট করুন'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
