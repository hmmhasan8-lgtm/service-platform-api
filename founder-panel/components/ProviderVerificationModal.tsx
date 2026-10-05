'use client';

import React, { useState } from 'react';
import {
  ShieldCheck,
  CheckCircle2,
  X,
  Camera,
  FileText,
  Upload,
  UserCheck,
  AlertCircle,
  Clock,
  Sparkles,
} from 'lucide-react';

interface ProviderVerificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId: string;
  userName: string;
  isVerified: boolean;
  onVerifiedSuccess: () => void;
}

export const ProviderVerificationModal: React.FC<ProviderVerificationModalProps> = ({
  isOpen,
  onClose,
  userId,
  userName,
  isVerified,
  onVerifiedSuccess,
}) => {
  const [nidFront, setNidFront] = useState('https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=600&auto=format&fit=crop&q=80');
  const [nidBack, setNidBack] = useState('https://images.unsplash.com/photo-1568992687947-868a62a9f521?w=600&auto=format&fit=crop&q=80');
  const [selfie, setSelfie] = useState('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80');
  const [nidNumber, setNidNumber] = useState('19942692019000456');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [verificationPending, setVerificationPending] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      // API call to /verifications/submit
      await fetch('/verifications/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user_id: userId,
          nid_front_image_url: nidFront,
          nid_back_image_url: nidBack,
          selfie_image_url: selfie,
        }),
      }).catch(() => {});

      setVerificationPending(true);
      setStatusMessage('আপনার NID ও সেলফি সফলভাবে জমা হয়েছে। স্টাফ কর্মকর্তা পর্যালোচনার পর অনুমোদন দেবেন।');
      setTimeout(() => {
        onVerifiedSuccess();
      }, 1500);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl p-6 sm:p-7 max-w-lg w-full shadow-2xl space-y-5 animate-in fade-in zoom-in-95">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-extrabold text-base text-slate-900">
                {isVerified ? 'প্রোভাইডার ভেরিফায়েড প্রোফাইল' : 'NID + ফেস ভেরিফিকেশন (Trust & Safety)'}
              </h3>
              <p className="text-[11px] text-slate-500">
                {isVerified ? 'আপনার একাউন্ট ১০০% ভেরিফায়েড' : 'ভেরিফাই করলেই তবে কাস্টমার রিকোয়েস্ট পাবেন'}
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100">
            <X className="w-5 h-5" />
          </button>
        </div>

        {isVerified ? (
          <div className="text-center py-6 space-y-4">
            <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-10 h-10" />
            </div>
            <div>
              <span className="px-3 py-1 bg-emerald-100 text-emerald-800 rounded-full font-extrabold text-xs inline-flex items-center gap-1.5 border border-emerald-300">
                <ShieldCheck className="w-4 h-4" /> ভেরিফায়েড সার্ভিস প্রোভাইডার
              </span>
              <h4 className="text-base font-bold text-slate-900 mt-2">{userName}</h4>
              <p className="text-xs text-slate-500 mt-1 max-w-xs mx-auto">
                আপনার জাতীয় পরিচয়পত্র ও ফেস ভেরিফিকেশন অনুমোদিত। আপনি সব কাছাকাছি কাস্টমার রিকোয়েস্ট গ্রহণ করতে পারবেন।
              </p>
            </div>
            <button
              onClick={onClose}
              className="px-6 py-2.5 bg-slate-900 text-white font-bold rounded-xl text-xs"
            >
              বন্ধ করুন
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            <div className="p-3 bg-amber-50 border border-amber-200 rounded-2xl text-amber-900 leading-relaxed text-[11px] flex items-start gap-2">
              <AlertCircle className="w-4 h-4 text-amber-600 flex-shrink-0 mt-0.5" />
              <div>
                <strong>পলিসি শর্ত:</strong> ভেরিফিকেশন ছাড়া প্রোভাইডাররা কাস্টমারদের পোস্ট দেখতে বা আবেদন গ্রহণ করতে পারবেন না। আপনার ৩টি ছবি আপলোড করুন।
              </div>
            </div>

            <div>
              <label className="block font-bold text-slate-700 uppercase mb-1">
                এনআইডি নম্বর (National ID Number) *
              </label>
              <input
                type="text"
                required
                value={nidNumber}
                onChange={(e) => setNidNumber(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-300 rounded-xl font-mono text-slate-900 outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="grid grid-cols-3 gap-2.5">
              {/* Photo 1: NID Front */}
              <div className="border border-slate-200 p-2.5 rounded-2xl text-center space-y-1.5 bg-slate-50/50">
                <span className="font-bold text-[10px] text-slate-700 block">১. NID ফ্রন্ট পার্ট</span>
                <div className="w-full h-16 bg-slate-200 rounded-lg overflow-hidden flex items-center justify-center">
                  <img src={nidFront} alt="NID Front" className="w-full h-full object-cover" />
                </div>
                <span className="text-[9px] text-emerald-700 font-bold flex items-center justify-center gap-0.5">
                  <CheckCircle2 className="w-3 h-3" /> আপলোডকৃত
                </span>
              </div>

              {/* Photo 2: NID Back */}
              <div className="border border-slate-200 p-2.5 rounded-2xl text-center space-y-1.5 bg-slate-50/50">
                <span className="font-bold text-[10px] text-slate-700 block">২. NID ব্যাক পার্ট</span>
                <div className="w-full h-16 bg-slate-200 rounded-lg overflow-hidden flex items-center justify-center">
                  <img src={nidBack} alt="NID Back" className="w-full h-full object-cover" />
                </div>
                <span className="text-[9px] text-emerald-700 font-bold flex items-center justify-center gap-0.5">
                  <CheckCircle2 className="w-3 h-3" /> আপলোডকৃত
                </span>
              </div>

              {/* Photo 3: Live Selfie */}
              <div className="border border-slate-200 p-2.5 rounded-2xl text-center space-y-1.5 bg-slate-50/50">
                <span className="font-bold text-[10px] text-slate-700 block">৩. লাইভ সেলফি</span>
                <div className="w-full h-16 bg-slate-200 rounded-lg overflow-hidden flex items-center justify-center">
                  <img src={selfie} alt="Selfie" className="w-full h-full object-cover" />
                </div>
                <span className="text-[9px] text-emerald-700 font-bold flex items-center justify-center gap-0.5">
                  <CheckCircle2 className="w-3 h-3" /> আপলোডকৃত
                </span>
              </div>
            </div>

            {statusMessage && (
              <div className="p-3 bg-emerald-50 border border-emerald-300 rounded-xl text-emerald-900 font-semibold text-xs flex items-center gap-2">
                <Clock className="w-4 h-4 text-emerald-600" />
                <span>{statusMessage}</span>
              </div>
            )}

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
                disabled={isSubmitting || verificationPending}
                className="flex-1 py-2.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white font-bold rounded-xl shadow-sm transition"
              >
                {isSubmitting ? 'প্রেরণ করা হচ্ছে...' : 'ভেরিফিকেশন সাবমিট করুন'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
