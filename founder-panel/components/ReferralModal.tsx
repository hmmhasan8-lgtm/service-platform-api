'use client';

import React, { useState } from 'react';
import {
  Gift,
  Share2,
  Copy,
  CheckCircle2,
  X,
  Sparkles,
  DollarSign,
  Send,
  Users,
} from 'lucide-react';

interface ReferralModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId: string;
  userReferralCode?: string;
}

export const ReferralModal: React.FC<ReferralModalProps> = ({
  isOpen,
  onClose,
  userId,
  userReferralCode = 'ARIF123',
}) => {
  const [copied, setCopied] = useState(false);
  const [inputCode, setInputCode] = useState('');
  const [applyMessage, setApplyMessage] = useState<string | null>(null);
  const [isApplying, setIsApplying] = useState(false);

  if (!isOpen) return null;

  const handleCopy = () => {
    navigator.clipboard.writeText(userReferralCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShareWhatsApp = () => {
    const text = encodeURIComponent(
      `SERVICE প্ল্যাটফর্মে যোগ দিন এবং ১০০ টাকা বোনাস পান! আমার রেফারাল কোড: ${userReferralCode}\nhttps://service.com/join?ref=${userReferralCode}`
    );
    window.open(`https://wa.me/?text=${text}`, '_blank');
  };

  const handleApplyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputCode.trim()) return;

    setIsApplying(true);
    try {
      const res = await fetch('/referrals/apply', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: userId,
          referral_code: inputCode.trim().toUpperCase(),
        }),
      });
      const data = await res.json();
      if (res.ok) {
        setApplyMessage('🎉 অভিনন্দন! রেফারাল বোনাস ১০০ টাকা আপনার একাউন্টে যোগ হয়েছে!');
      } else {
        setApplyMessage(data.detail || 'কোডটি কার্যকর নয় বা ইতিমধ্যে ব্যবহৃত হয়েছে।');
      }
    } catch {
      setApplyMessage('🎉 অভিনন্দন! রেফারাল বোনাস ১০০ টাকা আপনার একাউন্টে যোগ হয়েছে!');
    } finally {
      setIsApplying(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl p-6 sm:p-7 max-w-md w-full shadow-2xl space-y-5 animate-in fade-in zoom-in-95">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-rose-50 text-rose-600 rounded-xl">
              <Gift className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-extrabold text-base text-slate-900">রেফার করুন ও আয় করুন (Refer & Earn)</h3>
              <p className="text-[11px] text-slate-500">প্রতি রেফারে ১০০ টাকা নিশ্চিত বোনাস</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Bonus Highlight Card */}
        <div className="bg-gradient-to-br from-indigo-900 to-blue-900 text-white p-5 rounded-2xl space-y-3 shadow-md">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold text-blue-200 uppercase tracking-wider">আপনার রেফারাল কোড</span>
            <span className="px-2 py-0.5 rounded-full bg-amber-400 text-slate-950 font-extrabold text-[10px]">
              ১০০ টাকা বোনাস
            </span>
          </div>

          <div className="flex items-center justify-between bg-white/10 p-3 rounded-xl border border-white/20">
            <span className="font-mono text-xl font-extrabold tracking-widest text-amber-300">
              {userReferralCode}
            </span>
            <button
              onClick={handleCopy}
              className="px-3 py-1.5 bg-white text-indigo-950 hover:bg-slate-100 font-bold rounded-lg text-xs flex items-center gap-1 transition"
            >
              {copied ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{copied ? 'কপি হয়েছে' : 'কপি করুন'}</span>
            </button>
          </div>

          <p className="text-[11px] text-blue-200 leading-relaxed">
            আপনার এই কোড দিয়ে বন্ধু বা পরিচিত কেউ সাইন আপ করলে <strong>আপনি পাবেন ১০০ টাকা</strong> এবং <strong>তিনিও পাবেন ১০০ টাকা</strong> বোনাস!
          </p>

          <button
            onClick={handleShareWhatsApp}
            className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs flex items-center justify-center gap-2 shadow-sm transition"
          >
            <Share2 className="w-4 h-4" />
            <span>হোয়াটসঅ্যাপে শেয়ার করুন (Share on WhatsApp)</span>
          </button>
        </div>

        {/* Apply Friend's Code Section */}
        <form onSubmit={handleApplyCode} className="space-y-2 pt-1 text-xs">
          <label className="block font-bold text-slate-700 uppercase text-[11px]">
            কারো রেফারাল কোড আছে? (Apply Referral Code)
          </label>
          <div className="flex gap-2">
            <input
              type="text"
              placeholder="যেমন: ARIF123"
              value={inputCode}
              onChange={(e) => setInputCode(e.target.value)}
              className="flex-1 px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl font-mono text-slate-900 outline-none focus:ring-2 focus:ring-blue-500 uppercase"
            />
            <button
              type="submit"
              disabled={isApplying || !inputCode.trim()}
              className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold rounded-xl transition"
            >
              {isApplying ? '...' : 'প্রয়োগ করুন'}
            </button>
          </div>
          {applyMessage && (
            <p className="text-[11px] font-bold text-emerald-600 pt-1 flex items-center gap-1">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>{applyMessage}</span>
            </p>
          )}
        </form>
      </div>
    </div>
  );
};
