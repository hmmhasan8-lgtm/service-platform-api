'use client';

import React, { useState } from 'react';
import {
  Zap,
  MapPin,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  RotateCcw,
  ShieldCheck,
  Radio,
  Clock,
  ArrowRight,
  MessageSquare,
  DollarSign,
  User,
  Users,
  Star,
  Award,
  Tag,
  Gift,
} from 'lucide-react';

export interface ProviderItem {
  id: string;
  name: string;
  location: string;
  lat: number;
  lng: number;
  distanceKm: number;
  isNearby: boolean;
  is_verified: boolean;
  level: 'Platinum' | 'Gold' | 'Silver' | 'New';
  rating: number;
  reviewsCount: number;
  feeCharged: number;
  status: 'idle' | 'winner' | 'rejected_409';
  rejectionReason: string | null;
}

export const SingleWinnerSimulator: React.FC = () => {
  // Category-wise dynamic fee settings (MODULE 4 A)
  const categoryFees: Record<string, { label: string; fee: number }> = {
    ac_repair: { label: 'এসি সার্ভিসিং (AC Repair)', fee: 50 },
    electrician: { label: 'ইলেকট্রিশিয়ান (Electrician)', fee: 100 },
    vehicle_rental: { label: 'যানবাহন ভাড়া (Vehicle Rental)', fee: 120 },
  };

  const [selectedCategoryKey, setSelectedCategoryKey] = useState<string>('ac_repair');

  // State for Service Request
  const [requestState, setRequestState] = useState<{
    id: string;
    seekerName: string;
    title: string;
    category: string;
    location: string;
    lat: number;
    lng: number;
    fee: number;
    currency: string;
    status: 'open' | 'accepted';
    winnerId: string | null;
    winnerName: string | null;
    acceptedAt: string | null;
    seekerFeeCharged: boolean;
  }>({
    id: 'req_mirpur_881',
    seekerName: 'তানভীর আহমেদ (গ্রাহক)',
    title: 'জরুরী স্প্লিট এসি গ্যাস চার্জ ও মেরামত প্রয়োজন',
    category: 'এসি সার্ভিসিং (AC Repair)',
    location: 'মিরপুর ১০, ঢাকা',
    lat: 23.8069,
    lng: 90.3687,
    fee: 50,
    currency: 'BDT',
    status: 'open',
    winnerId: null,
    winnerName: null,
    acceptedAt: null,
    seekerFeeCharged: false,
  });

  // MODULE 3: Coupon State
  const [couponCode, setCouponCode] = useState('');
  const [couponDiscount, setCouponDiscount] = useState<number>(0);
  const [couponMsg, setCouponMsg] = useState<string | null>(null);

  // Level weight mapping for MODULE 2 sorting ("Gold/Platinum দের Request আগে যাবে")
  const levelWeights: Record<string, number> = {
    Platinum: 4,
    Gold: 3,
    Silver: 2,
    New: 1,
  };

  // Providers list with location proximity, NID verification, and Gamification level
  const [providers, setProviders] = useState<ProviderItem[]>([
    {
      id: 'prov_1',
      name: 'রহিম এসি সলিউশন',
      location: 'মিরপুর ১১, ঢাকা',
      lat: 23.8150,
      lng: 90.3650,
      distanceKm: 0.98,
      isNearby: true,
      is_verified: true, // MODULE 1: Verified
      level: 'Platinum' as const, // MODULE 2: Level
      rating: 4.9,
      reviewsCount: 140,
      feeCharged: 0,
      status: 'idle' as 'idle' | 'winner' | 'rejected_409',
      rejectionReason: null as string | null,
    },
    {
      id: 'prov_2',
      name: 'করিম ইলেকট্রনিক্স ও এসি',
      location: 'মিরপুর ২, ঢাকা',
      lat: 23.8010,
      lng: 90.3550,
      distanceKm: 1.54,
      isNearby: true,
      is_verified: true, // MODULE 1: Verified
      level: 'Gold' as const, // MODULE 2: Level
      rating: 4.8,
      reviewsCount: 120,
      feeCharged: 0,
      status: 'idle' as 'idle' | 'winner' | 'rejected_409',
      rejectionReason: null as string | null,
    },
    {
      id: 'prov_unverified',
      name: 'আলমগীর টেকনিশিয়ান',
      location: 'মিরপুর ১০, ঢাকা',
      lat: 23.8060,
      lng: 90.3680,
      distanceKm: 0.45,
      isNearby: true,
      is_verified: false, // MODULE 1: Unverified
      level: 'Silver' as const,
      rating: 4.6,
      reviewsCount: 24,
      feeCharged: 0,
      status: 'idle' as 'idle' | 'winner' | 'rejected_409',
      rejectionReason: 'NID Verify করুন, তারপর Request পাবেন',
    },
    {
      id: 'prov_3',
      name: 'হাসান টেকনিশিয়ান',
      location: 'আগ্রাবাদ, চট্টগ্রাম',
      lat: 22.3250,
      lng: 91.8150,
      distanceKm: 216.5,
      isNearby: false,
      is_verified: true,
      level: 'Gold' as const,
      rating: 4.7,
      reviewsCount: 65,
      feeCharged: 0,
      status: 'idle' as 'idle' | 'winner' | 'rejected_409',
      rejectionReason: 'দূরবর্তী এলাকা (>৫ কিমি), নোটিফিকেশন পাঠানো হয়নি',
    },
  ]);

  const [raceLog, setRaceLog] = useState<string[]>([
    '📢 গ্রাহক তানভীর আহমেদ মিরপুর ১০ থেকে রিকোয়েস্ট পোস্ট করেছেন।',
    '🛡️ ট্রাস্ট ও সেফটি ফিল্টার: শুধুমাত্র NID Verified প্রোভাইডাররা রিকোয়েস্ট গ্রহণ করতে পারবেন।',
    '⭐ গ্যামিফিকেশন র‍্যাংকিং সক্রিয়: Platinum ও Gold লেভেলের প্রোভাইডারদের কাছে নোটিফিকেশন সবার আগে পৌঁছেছে।',
    '📡 লোকেশন ফিল্টার সক্রিয়: ৫ কিমি দূরত্বের মধ্যে রহিম ও করিমকে অ্যালার্ট পাঠানো হয়েছে। চট্টগ্রাম থেকে হাসানকে বাইরে রাখা হয়েছে।',
  ]);

  // Handle Category Dynamic Fee Switch (MODULE 4 A)
  const handleCategoryChange = (catKey: string) => {
    const cat = categoryFees[catKey];
    if (!cat) return;
    setSelectedCategoryKey(catKey);
    setRequestState((prev) => ({
      ...prev,
      category: cat.label,
      fee: cat.fee,
    }));
    setRaceLog((prev) => [
      `⚙️ [FOUNDER DYNAMIC COMMISSION] ক্যাটাগরি পরিবর্তিত: '${cat.label}', নির্ধারিত ম্যাচিং ফি: ৳${cat.fee} BDT (কোড ছাড়াই পরিবর্তিত)`,
      ...prev,
    ]);
  };

  // Validate & Apply Coupon (MODULE 3)
  const handleApplyCoupon = () => {
    const clean = couponCode.trim().toUpperCase();
    if (clean === 'EID50') {
      setCouponDiscount(50);
      setCouponMsg('🎉 কুপন EID50 সফল! ৫০% ছাড় প্রযোজ্য হয়েছে।');
      setRaceLog((prev) => [
        `🏷️ [MARKETING COUPON] কুপন 'EID50' সক্রিয়: ৫০% ডিসকাউন্ট! ফি ৳${requestState.fee} থেকে কমে ৳${Math.round(requestState.fee * 0.5)} BDT হয়েছে।`,
        ...prev,
      ]);
    } else if (clean === 'SERVICE20') {
      setCouponDiscount(20);
      setCouponMsg('🎉 কুপন SERVICE20 সফল! ২০% ছাড় প্রযোজ্য হয়েছে।');
    } else if (clean === 'PROMO100') {
      setCouponDiscount(100);
      setCouponMsg('🎉 কুপন PROMO100 সফল! ১০০% ফ্রি আনলক!');
    } else {
      setCouponDiscount(0);
      setCouponMsg('❌ কুপন কোড সঠিক নয় অথবা মেয়াদোত্তীর্ণ।');
    }
  };

  // Calculate final fee after coupon
  const finalEffectiveFee = Math.max(0, Math.round(requestState.fee * (1 - couponDiscount / 100)));

  // Core Race Condition & Single-Winner Accept Handler
  const handleAccept = (providerId: string) => {
    const prov = providers.find((p) => p.id === providerId);
    if (!prov) return;

    // MODULE 1: Guard against unverified providers
    if (!prov.is_verified) {
      setRaceLog((prev) => [
        `🚫 [BLOCKED] ${prov.name} ভেরিফাইড নন! "NID Verify করুন, তারপর Request পাবেন" নীতি কার্যকর।`,
        ...prev,
      ]);
      return;
    }

    // CRITICAL ROW-LOCK CHECK:
    if (requestState.status !== 'open' || requestState.winnerId !== null) {
      // Already claimed by another provider -> HTTP 409 Conflict
      setProviders((prev) =>
        prev.map((p) =>
          p.id === providerId
            ? {
                ...p,
                status: 'rejected_409',
                feeCharged: 0,
                rejectionReason:
                  '🛑 HTTP 409: এই রিকোয়েস্টটি ইতিমধ্যে অন্য একজন সার্ভিস প্রোভাইডার গ্রহণ করেছেন। বাকিরা বাদ পড়বেন। আপনার কোনো ফি কাটা হয়নি।',
              }
            : p
        )
      );
      setRaceLog((prev) => [
        `❌ [HTTP 409 Conflict] ${prov.name} গ্রহণ করতে চেয়েছিলেন, কিন্তু ইতিমধ্যে অন্য কেউ গ্রহণ করেছেন! কোনো ফি কাটা হয়নি (৳০)।`,
        ...prev,
      ]);
      return;
    }

    // FIRST WINNER CLAIMS THE REQUEST
    const now = new Date().toLocaleTimeString('bn-BD');
    setRequestState((prev) => ({
      ...prev,
      status: 'accepted',
      winnerId: prov.id,
      winnerName: prov.name,
      acceptedAt: now,
      seekerFeeCharged: true,
    }));

    setProviders((prev) =>
      prev.map((p) =>
        p.id === providerId
          ? {
              ...p,
              status: 'winner',
              feeCharged: finalEffectiveFee,
              rejectionReason: null,
            }
          : p
      )
    );

    setRaceLog((prev) => [
      `🏆 [SINGLE WINNER] ${prov.name} (${prov.level} Level) প্রথম রিকোয়েস্ট গ্রহণ করেছেন! বিজয়ী প্রোভাইডারের থেকে ৳${finalEffectiveFee} এবং গ্রাহকের থেকে ৳${requestState.fee} ফি কর্তন করা হয়েছে। স্ট্যাটাস সম্পূর্ণ লক হয়ে গেছে।`,
      ...prev,
    ]);
  };

  // Simulate Simultaneous Click Race Condition
  const handleSimultaneousRace = () => {
    // Provider 1 clicks first (at t=0ms), Provider 2 clicks at t=150ms
    handleAccept('prov_1');
    setTimeout(() => {
      handleAccept('prov_2');
    }, 150);
  };

  const handleReset = () => {
    setRequestState({
      id: 'req_mirpur_881',
      seekerName: 'তানভীর আহমেদ (গ্রাহক)',
      title: 'জরুরী স্প্লিট এসি গ্যাস চার্জ ও মেরামত প্রয়োজন',
      category: categoryFees[selectedCategoryKey]?.label || 'এসি সার্ভিসিং (AC Repair)',
      location: 'মিরপুর ১০, ঢাকা',
      lat: 23.8069,
      lng: 90.3687,
      fee: categoryFees[selectedCategoryKey]?.fee || 50,
      currency: 'BDT',
      status: 'open',
      winnerId: null,
      winnerName: null,
      acceptedAt: null,
      seekerFeeCharged: false,
    });

    setProviders([
      {
        id: 'prov_1',
        name: 'রহিম এসি সলিউশন',
        location: 'মিরপুর ১১, ঢাকা',
        lat: 23.8150,
        lng: 90.3650,
        distanceKm: 0.98,
        isNearby: true,
        is_verified: true,
        level: 'Platinum',
        rating: 4.9,
        reviewsCount: 140,
        feeCharged: 0,
        status: 'idle',
        rejectionReason: null,
      },
      {
        id: 'prov_2',
        name: 'করিম ইলেকট্রনিক্স ও এসি',
        location: 'মিরপুর ২, ঢাকা',
        lat: 23.8010,
        lng: 90.3550,
        distanceKm: 1.54,
        isNearby: true,
        is_verified: true,
        level: 'Gold',
        rating: 4.8,
        reviewsCount: 120,
        feeCharged: 0,
        status: 'idle',
        rejectionReason: null,
      },
      {
        id: 'prov_unverified',
        name: 'আলমগীর টেকনিশিয়ান',
        location: 'মিরপুর ১০, ঢাকা',
        lat: 23.8060,
        lng: 90.3680,
        distanceKm: 0.45,
        isNearby: true,
        is_verified: false,
        level: 'Silver',
        rating: 4.6,
        reviewsCount: 24,
        feeCharged: 0,
        status: 'idle',
        rejectionReason: 'NID Verify করুন, তারপর Request পাবেন',
      },
      {
        id: 'prov_3',
        name: 'হাসান টেকনিশিয়ান',
        location: 'আগ্রাবাদ, চট্টগ্রাম',
        lat: 22.3250,
        lng: 91.8150,
        distanceKm: 216.5,
        isNearby: false,
        is_verified: true,
        level: 'Gold',
        rating: 4.7,
        reviewsCount: 65,
        feeCharged: 0,
        status: 'idle',
        rejectionReason: 'দূরবর্তী এলাকা (>৫ কিমি), নোটিফিকেশন পাঠানো হয়নি',
      },
    ]);

    setRaceLog([
      '📢 গ্রাহক তানভীর আহমেদ মিরপুর ১০ থেকে রিকোয়েস্ট পোস্ট করেছেন।',
      '🛡️ ট্রাস্ট ও সেফটি ফিল্টার: শুধুমাত্র NID Verified প্রোভাইডাররা রিকোয়েস্ট গ্রহণ করতে পারবেন।',
      '⭐ গ্যামিফিকেশন র‍্যাংকিং সক্রিয়: Platinum ও Gold লেভেলের প্রোভাইডারদের কাছে নোটিফিকেশন সবার আগে পৌঁছেছে।',
      '📡 লোকেশন ফিল্টার সক্রিয়: ৫ কিমি দূরত্বের মধ্যে রহিম ও করিমকে অ্যালার্ট পাঠানো হয়েছে। চট্টগ্রাম থেকে হাসানকে বাইরে রাখা হয়েছে।',
    ]);
  };

  // Sort providers by Gamification Level DESC so Platinum & Gold receive notifications first (MODULE 2)
  const sortedProviders = [...providers].sort((a, b) => {
    return (levelWeights[b.level] || 0) - (levelWeights[a.level] || 0);
  });

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      {/* Top Banner Explaining Corrected Single Winner & 4 Modules */}
      <div className="bg-gradient-to-r from-blue-900 via-indigo-900 to-slate-900 text-white p-5 rounded-2xl shadow-sm border border-blue-800">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-amber-400 fill-amber-400" />
              <h2 className="text-base font-bold tracking-wide">
                একক বিজয়ী ও ৪-মডিউল পাওয়ার সিমুলেটর (Single-Winner Engine)
              </h2>
              <span className="px-2 py-0.5 bg-amber-400 text-slate-950 font-extrabold text-[10px] rounded-full uppercase">
                Single Winner Logic
              </span>
            </div>
            <p className="text-xs text-blue-200 mt-1 max-w-3xl leading-relaxed">
              &quot;যিনি সেবা গ্রহণ করবেন তিনি পোস্ট করার পর তার কাছাকাছি লোকেশনে যারা থাকবে তাদের মধ্যে যিনি আগে রিকুয়েস্ট গ্রহণ করবেন শুধু তার কাছ থেকেই ফি কাটা হবে এবং রিকোয়েস্ট দাতার কাছ থেকে ফি কাটা হবে। একসাথে একাধিক ব্যক্তি ক্লিক করলেও শুধুমাত্র ১ জনের ফি কাটা হবে, বাকিরা ৪০৯ কনফ্লিক্ট হয়ে বাদ পড়বেন।&quot;
            </p>
          </div>

          <div className="flex gap-2">
            <button
              onClick={handleSimultaneousRace}
              disabled={requestState.status === 'accepted'}
              className="px-3.5 py-2 bg-amber-500 hover:bg-amber-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs flex items-center gap-1.5 shadow-sm transition"
            >
              <Zap className="w-4 h-4 fill-slate-950" />
              একসাথে গ্রহণের চেষ্টা সিমুলেশন
            </button>
            <button
              onClick={handleReset}
              className="px-3.5 py-2 bg-white/10 hover:bg-white/20 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 border border-white/20 transition"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              রিসেট
            </button>
          </div>
        </div>
      </div>

      {/* Grid: Left = Seeker Request & Dynamic Fee & Coupon, Right = Nearby Providers Push */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {/* 1. Seeker Service Request Card */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <User className="w-4 h-4 text-blue-600" />
              <span className="font-bold text-xs text-slate-800">সেবা গ্রহীতার রিকোয়েস্ট</span>
            </div>
            <span
              className={`px-2 py-0.5 text-[10px] font-bold rounded-full uppercase ${
                requestState.status === 'open'
                  ? 'bg-amber-100 text-amber-800 border border-amber-300 animate-pulse'
                  : 'bg-emerald-100 text-emerald-800 border border-emerald-300'
              }`}
            >
              {requestState.status === 'open' ? 'উন্মুক্ত (Open)' : 'লকড (Accepted)'}
            </span>
          </div>

          <div>
            <h3 className="font-bold text-sm text-slate-900 leading-snug">{requestState.title}</h3>
            <p className="text-xs text-slate-500 mt-1">পোস্টার: {requestState.seekerName}</p>
          </div>

          {/* MODULE 4 A: Dynamic Category-wise Commission Selector */}
          <div className="space-y-1.5 pt-1">
            <label className="text-[10px] font-bold uppercase text-slate-500 block">
              ক্যাটাগরি ভিত্তিক ডায়নামিক কমিশন (Module 4 A):
            </label>
            <div className="grid grid-cols-1 gap-1.5">
              {Object.entries(categoryFees).map(([k, cfg]) => (
                <button
                  key={k}
                  onClick={() => handleCategoryChange(k)}
                  disabled={requestState.status === 'accepted'}
                  className={`px-2.5 py-1.5 rounded-lg text-left text-xs font-semibold flex items-center justify-between transition ${
                    selectedCategoryKey === k
                      ? 'bg-indigo-50 border border-indigo-300 text-indigo-900 font-bold'
                      : 'bg-slate-50 border border-slate-200 text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <span className="truncate">{cfg.label}</span>
                  <span className="font-mono text-emerald-700 ml-1">৳{cfg.fee}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="p-3 bg-slate-50 rounded-xl space-y-2 text-xs">
            <div className="flex items-center justify-between text-slate-600">
              <span className="flex items-center gap-1">
                <MapPin className="w-3.5 h-3.5 text-rose-500" /> লোকেশন:
              </span>
              <span className="font-bold text-slate-900">{requestState.location}</span>
            </div>
            <div className="flex items-center justify-between text-slate-600">
              <span>মূল ম্যাচিং ফি:</span>
              <span className="font-bold text-slate-900 font-mono">৳{requestState.fee} / জন</span>
            </div>
          </div>

          {/* MODULE 3: Coupon Code Input on Accept / Simulator Card */}
          <div className="p-3 bg-indigo-50/50 rounded-xl border border-indigo-100 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-indigo-900 flex items-center gap-1">
                <Tag className="w-3.5 h-3.5 text-indigo-600" />
                কুপন কোড (Module 3 Marketing):
              </span>
              <span className="text-[10px] text-slate-500 font-mono">Try: EID50</span>
            </div>
            <div className="flex gap-1.5">
              <input
                type="text"
                placeholder="যেমন: EID50"
                value={couponCode}
                onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                disabled={requestState.status === 'accepted'}
                className="flex-1 px-2.5 py-1 text-xs bg-white border border-slate-300 rounded-lg font-mono outline-none uppercase font-bold"
              />
              <button
                type="button"
                onClick={handleApplyCoupon}
                disabled={requestState.status === 'accepted'}
                className="px-3 py-1 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-bold rounded-lg text-xs"
              >
                Apply
              </button>
            </div>
            {couponMsg && (
              <p className={`text-[10px] font-bold ${couponDiscount > 0 ? 'text-emerald-700' : 'text-rose-600'}`}>
                {couponMsg}
              </p>
            )}
            {couponDiscount > 0 && (
              <div className="flex justify-between items-center text-xs pt-1 border-t border-indigo-200/50 font-bold text-indigo-900">
                <span>ছাড়ের পর প্রোভাইডার ফি:</span>
                <span className="text-emerald-700 font-mono font-extrabold">৳{finalEffectiveFee} BDT</span>
              </div>
            )}
          </div>

          {/* Fee Settlement Status for Seeker */}
          <div className="p-3 rounded-xl border text-xs space-y-1">
            <span className="text-[11px] font-bold uppercase text-slate-400 block">গ্রাহকের ফি স্ট্যাটাস:</span>
            {requestState.seekerFeeCharged ? (
              <div className="flex items-center gap-1.5 text-emerald-700 font-bold">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>৳{requestState.fee} কর্তন সম্পন্ন (ম্যাচিং নিশ্চিত)</span>
              </div>
            ) : (
              <div className="flex items-center gap-1.5 text-slate-500">
                <Clock className="w-4 h-4 text-slate-400" />
                <span>প্রথম প্রোভাইডার গ্রহণ করলে কাটা হবে (এখনও কাটা হয়নি)</span>
              </div>
            )}
          </div>

          {requestState.status === 'accepted' && (
            <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-xs space-y-1">
              <span className="font-bold text-emerald-900 flex items-center gap-1">
                <ShieldCheck className="w-4 h-4 text-emerald-600" />
                একক বিজয়ী নির্ধারিত হয়েছে:
              </span>
              <p className="text-emerald-800 font-semibold">{requestState.winnerName}</p>
              <p className="text-[10px] text-emerald-600">গৃহীত সময়: {requestState.acceptedAt}</p>
            </div>
          )}
        </div>

        {/* 2. Nearby Providers Listening in Real-time (2 Columns) */}
        <div className="md:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Radio className="w-4 h-4 text-emerald-600 animate-ping" />
              <h3 className="font-bold text-sm text-slate-900">
                কাছাকাছি সার্ভিস প্রোভাইডারদের নোটিফিকেশন ডেস্ক (Location & Level Proximity)
              </h3>
            </div>
            <span className="text-xs text-slate-500 font-medium">
              সর্বোচ্চ ব্যাসার্ধ: <strong className="text-slate-800">৫ কিলোমিটার</strong>
            </span>
          </div>

          <div className="space-y-3">
            {sortedProviders.map((prov) => (
              <div
                key={prov.id}
                className={`p-4 rounded-2xl border transition-all ${
                  prov.status === 'winner'
                    ? 'bg-emerald-50/70 border-2 border-emerald-500 shadow-sm'
                    : prov.status === 'rejected_409'
                    ? 'bg-rose-50/70 border-2 border-rose-300'
                    : !prov.isNearby
                    ? 'bg-slate-50 border-slate-200 opacity-60'
                    : !prov.is_verified
                    ? 'bg-amber-50/40 border-amber-200'
                    : 'bg-white border-slate-200 hover:border-slate-300 shadow-xs'
                }`}
              >
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-bold text-sm text-slate-900">{prov.name}</span>

                      {/* MODULE 1: Verified Badge */}
                      {prov.is_verified ? (
                        <span className="px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200 text-[10px] font-bold flex items-center gap-1">
                          <ShieldCheck className="w-3 h-3 text-emerald-600" /> NID Verified ✅
                        </span>
                      ) : (
                        <span className="px-2 py-0.5 rounded-full bg-rose-50 text-rose-800 border border-rose-200 text-[10px] font-bold flex items-center gap-1">
                          <AlertTriangle className="w-3 h-3 text-rose-600" /> আনভেরিফায়েড ❌
                        </span>
                      )}

                      {/* MODULE 2: Level & Rating Badge */}
                      <span className="px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200 text-[10px] font-bold flex items-center gap-1">
                        <Award className="w-3 h-3 text-indigo-600" /> {prov.level} Level
                      </span>

                      <span className="text-amber-500 text-xs font-bold flex items-center gap-0.5">
                        ⭐ {prov.rating} ({prov.reviewsCount})
                      </span>

                      <span
                        className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                          prov.isNearby
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-slate-200 text-slate-600'
                        }`}
                      >
                        {prov.distanceKm} km দূরে
                      </span>

                      {prov.status === 'winner' && (
                        <span className="px-2 py-0.5 rounded bg-emerald-600 text-white text-[10px] font-extrabold flex items-center gap-1">
                          <CheckCircle2 className="w-3 h-3" /> বিজয়ী (Single Winner)
                        </span>
                      )}
                      {prov.status === 'rejected_409' && (
                        <span className="px-2 py-0.5 rounded bg-rose-600 text-white text-[10px] font-extrabold flex items-center gap-1">
                          <XCircle className="w-3 h-3" /> বাদ পড়েছেন (409 Conflict)
                        </span>
                      )}
                    </div>

                    <p className="text-xs text-slate-500 mt-1 flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5 text-slate-400" /> {prov.location}
                    </p>
                  </div>

                  {/* Accept Button or Status */}
                  <div>
                    {prov.isNearby ? (
                      prov.is_verified ? (
                        <button
                          onClick={() => handleAccept(prov.id)}
                          disabled={requestState.status === 'accepted' && prov.status === 'idle'}
                          className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                            prov.status === 'winner'
                              ? 'bg-emerald-600 text-white cursor-default'
                              : prov.status === 'rejected_409'
                              ? 'bg-rose-100 text-rose-800 cursor-not-allowed'
                              : requestState.status === 'accepted'
                              ? 'bg-slate-100 text-slate-400 cursor-not-allowed border border-slate-200'
                              : 'bg-blue-600 hover:bg-blue-700 text-white shadow-xs'
                          }`}
                        >
                          {prov.status === 'winner' ? (
                            <>
                              <CheckCircle2 className="w-3.5 h-3.5" /> গ্রহণ সম্পন্ন (৳{prov.feeCharged} কর্তন)
                            </>
                          ) : prov.status === 'rejected_409' ? (
                            <>
                              <XCircle className="w-3.5 h-3.5" /> রিকোয়েস্ট হাতছাড়া (৳০ কর্তন)
                            </>
                          ) : (
                            <>
                              <Zap className="w-3.5 h-3.5 fill-white" />
                              রিকোয়েস্ট গ্রহণ করুন ({couponDiscount > 0 ? `৳${finalEffectiveFee}` : `৳${requestState.fee}`})
                            </>
                          )}
                        </button>
                      ) : (
                        <button
                          disabled
                          className="px-3.5 py-2 rounded-xl text-[11px] font-bold bg-amber-100 text-amber-900 border border-amber-300 cursor-not-allowed flex items-center gap-1"
                          title="MODULE 1: NID ভেরিফিকেশন ছাড়া রিকোয়েস্ট গ্রহণ করা যাবে না"
                        >
                          <AlertTriangle className="w-3.5 h-3.5 text-amber-700" />
                          <span>NID Verify করুন, তারপর Request পাবেন</span>
                        </button>
                      )
                    ) : (
                      <span className="text-[11px] font-semibold text-slate-400 px-2 py-1 bg-slate-100 rounded-lg">
                        কাভারেজ এলাকার বাইরে
                      </span>
                    )}
                  </div>
                </div>

                {/* Rejection / Warning Note */}
                {prov.rejectionReason && (
                  <p className="text-xs text-rose-600 font-bold mt-2 pt-2 border-t border-rose-200/60 flex items-center gap-1">
                    <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" />
                    <span>{prov.rejectionReason}</span>
                  </p>
                )}

                {/* Financial Ledger for this provider */}
                <div className="mt-2 pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                  <span>কর্তনকৃত ফি:</span>
                  <span
                    className={`font-mono font-bold ${
                      prov.feeCharged > 0 ? 'text-emerald-700' : 'text-slate-400'
                    }`}
                  >
                    ৳{prov.feeCharged}.00 BDT
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Audit Log / Real-time Race Condition Terminal */}
      <div className="bg-slate-900 text-slate-100 p-5 rounded-2xl shadow-sm space-y-2 font-mono text-xs">
        <div className="flex items-center justify-between pb-2 border-b border-slate-800">
          <span className="text-slate-400 font-bold flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            লাইভ অডিট লগ (Race Condition & Single Winner Audit Stream)
          </span>
          <span className="text-[10px] text-slate-500">PostgreSQL with_for_update() Row Lock Active</span>
        </div>
        <div className="space-y-1.5 max-h-44 overflow-y-auto pt-1">
          {raceLog.map((log, index) => (
            <div key={index} className="leading-relaxed">
              <span className="text-slate-500 mr-2">&gt;</span>
              <span
                className={
                  log.includes('SINGLE WINNER')
                    ? 'text-emerald-400 font-bold'
                    : log.includes('409') || log.includes('BLOCKED')
                    ? 'text-rose-400 font-bold'
                    : log.includes('COUPON') || log.includes('COMMISSION')
                    ? 'text-amber-400 font-bold'
                    : 'text-slate-300'
                }
              >
                {log}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
